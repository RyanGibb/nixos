{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = 
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        mkHost = hostname: nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
          modules =
            [
              ./hosts/${hostname}/default.nix
              {
                networking.hostName = "${hostname}";
                # https://www.tweag.io/blog/2020-07-31-nixos-flakes#pinning-nixpkgs
                nix.registry.nixpkgs.flake = nixpkgs;
              }
            ];
        };
      in nixpkgs.lib.genAttrs hosts mkHost;
  };
}
