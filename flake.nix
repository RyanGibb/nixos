{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    gibbrdotorg.url = "github:RyanGibb/gibbr.org";
    gibbrdotorg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, gibbrdotorg, ... }@inputs: {

    nixosConfigurations =
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        mkHost = hostname:
        let system = builtins.readFile ./hosts/${hostname}/system; in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = inputs;
          pkgs =
            let overlays = [
              (final: prev: {
                unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
                # `gibbrdotorg.nixosModules.default` uses `pkgs."gibbr.org"`
                "gibbr.org" = gibbrdotorg.packages.${system}.with-cv;
              })
            ]; in
            import nixpkgs { inherit overlays system; config.allowUnfree = true; };
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
              gibbrdotorg.nixosModules.default
            ];
          };
      in nixpkgs.lib.genAttrs hosts mkHost;
    };
  }
