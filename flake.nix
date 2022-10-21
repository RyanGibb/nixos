{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    gibbrdotorg.url = "github:RyanGibb/gibbr.org";
    gibbrdotorg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, gibbrdotorg }@inputs: {

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
                # To add package from flake
                #<package name> = <input flake>.packages.${system}.default;
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
              gibbrdotorg.nixosModules."gibbr.org"
            ];
          };
      in nixpkgs.lib.genAttrs hosts mkHost;
    };
  }
