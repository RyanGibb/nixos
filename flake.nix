{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }@inputs: {

    nixosConfigurations =
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        mkHost = hostname:
          let system = builtins.readFile ./hosts/${hostname}/system; in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = inputs;
          modules =
            [
              ./hosts/${hostname}/default.nix
              home-manager.nixosModule
              {
                networking.hostName = "${hostname}";
                # https://www.tweag.io/blog/2020-07-31-nixos-flakes#pinning-nixpkgs
                nix.registry.nixpkgs.flake = nixpkgs;
                # https://nixos.wiki/wiki/Flakes#Importing_packages_from_multiple_channels
                nixpkgs.overlays =
                  let overlay-unstable = final: prev: {
                    unstable = import nixpkgs-unstable { config.allowUnfree = true; inherit system; };
                  }; in [ overlay-unstable ];
                system.stateVersion = "22.05";
              }
            ];
        };
      in nixpkgs.lib.genAttrs hosts mkHost;
  };
}
