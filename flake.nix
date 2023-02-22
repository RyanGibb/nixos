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

    getPkgs = system:
      let overlays = [
        (final: prev: {
          unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
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
      ]; in
      import nixpkgs { inherit overlays system; config.allowUnfree = true; };

    nixosConfigurations =
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        mkHost = config: hostname:
          let system = builtins.readFile ./hosts/${hostname}/system; in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = inputs;
            pkgs = getPkgs system;
            modules =
              [
                ./hosts/${hostname}/${config}.nix
                ./modules/default.nix
                eilean.nixosModules.default
                home-manager.nixosModule
                {
                  networking.hostName = "${hostname}";
                  # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
                  nix.registry.nixpkgs.flake = nixpkgs;
                  system.stateVersion = "22.05";
                  # record git revision (can be queried with `nixos-version --json)
                  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
                }
                ryan-website.nixosModules.default
                twitcher.nixosModules.default
                ocaml-dns-eio.nixosModules.default
              ];
            };
        mkHosts = hosts: nixpkgs.lib.genAttrs hosts (mkHost "default");
        mkConfigHosts = hosts: config:
          (builtins.listToAttrs (builtins.map (host: { name = "${host}-${config}"; value = mkHost config host; } ) hosts));
      in mkHosts hosts // mkConfigHosts hosts "minimal";

    packages.x86_64-linux.cctk =
      # TODO can use bellow to avoid explicitally having to import patchelf-new
      #with getPkgs "x86_64-linux";
      with import nixpkgs { system = "x86_64-linux"; };
      (pkgs.callPackage ./pkgs/cctk/default.nix { patchelf-raphi = patchelf-raphi.packages.${system}.patchelf; });
    };
}
