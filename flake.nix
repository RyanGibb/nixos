{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }@inputs: {

    nixosConfigurations =
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        mkHost = hostname:
        let system = builtins.readFile ./hosts/${hostname}/system; in
        nixpkgs.lib.nixosSystem {
          inherit system;
          _module.args = inputs;
          pkgs =
            let nixpkgs-config = { inherit system; config.allowUnfree = true; }; in
            import nixpkgs (
              nixpkgs-config //
              { overlays = [ (final: prev: { unstable = import nixpkgs-unstable nixpkgs-config; }) ]; }
            );
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
            ];
          };
      in nixpkgs.lib.genAttrs hosts mkHost;
    };
  }
