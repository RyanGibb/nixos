{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ryan-website.url = "git+ssh://git@git.freumh.org/ryan/website.git";
    ryan-website.inputs.nixpkgs.follows = "nixpkgs";
    twitcher.url = "git+ssh://git@git.freumh.org/ryan/twitcher.git";
    twitcher.inputs.nixpkgs.follows = "nixpkgs";
    patchelf-raphi.url = "git+https://git.sr.ht/~raphi/patchelf";
    patchelf-raphi.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ryan-website, patchelf-raphi, twitcher, ... }@inputs: rec {

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
        })
      ]; in
      import nixpkgs { inherit overlays system; config.allowUnfree = true; };

    nixosConfigurations =
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        mkHost = hostname:
          let system = builtins.readFile ./hosts/${hostname}/system; in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = inputs;
            pkgs = getPkgs system;
            modules =
              [
                ./hosts/${hostname}/default.nix
                home-manager.nixosModule
                {
                  networking.hostName = "${hostname}";
                  # https://www.tweag.io/blog/2020-07-31-nixos-flakes#pinning-nixpkgs
                  nix.registry.nixpkgs.flake = nixpkgs;
                  system.stateVersion = "22.05";
                  # record git revision (can be queried with `nixos-version --json)
                  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
                }
                ryan-website.nixosModules.default
                twitcher.nixosModules.default
              ];
            };
      in nixpkgs.lib.genAttrs hosts mkHost;

    packages.x86_64-linux.cctk =
      # TODO can use bellow to avoid explicitally having to import patchelf-new
      #with getPkgs "x86_64-linux";
      with import nixpkgs { system = "x86_64-linux"; };
      (pkgs.callPackage ./pkgs/cctk/default.nix { patchelf-raphi = patchelf-raphi.packages.${system}.patchelf; });
    };
  }
