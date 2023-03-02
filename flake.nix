{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager";
    patchelf-raphi.url = "git+https://git.sr.ht/~raphi/patchelf";
    eeww.url = "github:RyanGibb/eeww/nixos";
    ocaml-dns-eio.url = "github:RyanGibb/ocaml-dns-eio";

    eilean.url ="git+ssh://git@git.freumh.org/ryan/eilean-nix.git?ref=main";
    # eilean.url ="github:RyanGibb/eilean-nix/main";
    ryan-website.url = "git+ssh://git@git.freumh.org/ryan/website.git";
    ryan-cv.url = "git+ssh://git@git.freumh.org/ryan/cv.git";
    ryan-website.inputs.cv.follows = "ryan-cv";
    # ryan-website.url = "github:RyanGibb/website";
    twitcher.url = "git+ssh://git@git.freumh.org/ryan/twitcher.git";
    # twitcher.url = "github:RyanGibb/twitcher";

    # deduplicate flake inputs
    eilean.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    home-manager.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    ryan-website.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      flake-compat.follows = "flake-compat";
    };
    ryan-cv.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
    twitcher.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
    patchelf-raphi.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    eeww.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
    ocaml-dns-eio.inputs = {
      nixpkgs.follows = "nixpkgs";
      ipaddr.follows = "ipaddr";
      flake-utils.follows = "flake-utils";
      opam-nix.follows = "opam-nix";
    };
    opam-nix.url = "github:RyanGibb/opam-nix";
    opam-nix.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      flake-compat.follows = "flake-compat";
    };
    ipaddr.url = "github:RyanGibb/ocaml-ipaddr";
    ipaddr.inputs = {
      nixpkgs.follows = "nixpkgs";
      opam-nix.follows = "opam-nix";
      flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, eilean, home-manager, ryan-website, patchelf-raphi, twitcher, nixos-hardware, eeww, ocaml-dns-eio, ... }@inputs: rec {

    nixosConfigurations =
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        getSystemOverlays = system: nixpkgsConfig:
          [
            (final: prev: {
              unstable = import nixpkgs-unstable {
                inherit system;
                # follow stable nixpkgs config
                config = nixpkgsConfig;
              };
              # `ryan-website.nixosModules.default` uses `pkgs.ryan-website`
              "ryan-website" =
                let
                  keys = prev.stdenv.mkDerivation {
                    name = "ryan-keys";
                    src = ./modules/personal/authorized_keys;
                    phases = [ "buildPhase" ];
                    buildPhase = ''
                      touch $out
                      cat $src | cut -d' ' -f-2 > $out
                    '';
                  };
                in ryan-website.paramaterizedPackages.${system}.with-cv keys;
              # `twitcher.nixosModules.default` uses `pkgs.ryan-website`
              "twitcher" = twitcher.packages.${system}.default;
              # can uncomment if want to use patchelf-rafi elsewhere
              #"patchelf-raphi" = patchelf-raphi.packages.${system}.patchelf;
              # "cctk" = final.callPackage ./pkgs/cctk/default.nix { };
              "cctk" = prev.callPackage ./pkgs/cctk/default.nix { patchelf-raphi = patchelf-raphi.packages.${system}.patchelf; };
              "eeww" = eeww.defaultPackage.${system};
              "ocaml-dns-eio" = ocaml-dns-eio.defaultPackage.${system};
            })
          ];

        mkHost = mode: hostname:
          nixpkgs.lib.nixosSystem {
            # use system from config.localSystem
            # see https://github.com/NixOS/nixpkgs/blob/5297d584bcc5f95c8e87c631813b4e2ab7f19ecc/nixos/lib/eval-config.nix#L55
            system = null;
            pkgs = null;
            specialArgs = inputs;
            modules =
              [
                ./hosts/${hostname}/${mode}.nix
                ./modules/default.nix
                ({ config, ... }: {
                  networking.hostName = "${hostname}";
                  # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
                  nix.registry.nixpkgs.flake = nixpkgs;
                  system.stateVersion = "22.05";
                  # record git revision (can be queried with `nixos-version --json)
                  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
                  nixpkgs = {
                    config.allowUnfree = true;
                    overlays = getSystemOverlays config.nixpkgs.hostPlatform.system config.nixpkgs.config;
                  };
                })
                home-manager.nixosModule
                eilean.nixosModules.default
                ryan-website.nixosModules.default
                twitcher.nixosModules.default
                ocaml-dns-eio.nixosModules.default
              ];
            };
        mkHosts = hosts: nixpkgs.lib.genAttrs hosts (mkHost "default");
        mkModeHosts = mode: hosts:
          (builtins.listToAttrs (builtins.map (host: { name = "${host}-${mode}"; value = mkHost mode host; } ) hosts));
      in mkHosts hosts // mkModeHosts "minimal" hosts;

    packages.x86_64-linux.cctk =
      with import nixpkgs { system = "x86_64-linux"; };
      (pkgs.callPackage ./pkgs/cctk/default.nix { patchelf-raphi = patchelf-raphi.packages.${system}.patchelf; });
    };
}
