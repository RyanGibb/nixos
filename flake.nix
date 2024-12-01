{
  inputs = {
    nixpkgs-compat.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager-unstable.url = "github:nix-community/home-manager/master";
    agenix.url = "github:ryantm/agenix";
    deploy-rs.url = "github:serokell/deploy-rs";
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    eon.url = "github:RyanGibb/eon";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    alec-website.url = "github:alexanderhthompson/website";
    fn06-website.url = "github:RyanGibb/fn06";
    colour-guesser.url = "git+ssh://git@github.com/ryangibb/colour-guesser.git?ref=develop";
    i3-workspace-history.url = "github:RyanGibb/i3-workspace-history";
    hyperbib-eeg.url = "github:RyanGibb/hyperbib?ref=nixify";
    nix-rpi5.url = "gitlab:vriska/nix-rpi5?ref=main";

    # deduplicate flake inputs
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    eilean.inputs.eon.follows = "eon";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    alec-website.inputs.nixpkgs.follows = "nixpkgs";
    fn06-website.inputs.nixpkgs.follows = "nixpkgs";
    eon.inputs.nixpkgs.follows = "nixpkgs";
    colour-guesser.inputs.nixpkgs.follows = "nixpkgs";
    i3-workspace-history.inputs.nixpkgs.follows = "nixpkgs";
    hyperbib-eeg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs-compat,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      home-manager-unstable,
      agenix,
      deploy-rs,
      nix-on-droid,
      eilean,
      ...
    }@inputs:
    let
      getSystemOverlays = system: nixpkgsConfig: [
        (final: prev: {
          # https://github.com/mautrix/whatsapp/issues/749
          overlay-compat = import nixpkgs-compat {
            inherit system;
            # follow stable nixpkgs config
            config = nixpkgsConfig;
          };
          overlay-unstable = import nixpkgs-unstable {
            inherit system;
            # follow stable nixpkgs config
            config = nixpkgsConfig;
          };
          # to use an unstable version of a package
          #package = final.overlay-unstable.package;
          # to use an custom version of a package
          #package = prev.callPackage ./pkgs/package.nix { };
          # to use an unstable custom version of a package
          #package = final.callPackage ./pkgs/package.nix { };
          # to override attributes of a package
          # package = prev.package.overrideAttrs
          #  (_: { patches = [ ./pkgs/package.patch ]; });
          opam = final.overlay-unstable.opam.overrideAttrs (_: {
            src = final.fetchurl {
              url = "http://ryan.freumh.org/software/opam-full-2.3.0-nixos-depexts.tar.gz";
              sha256 = "sha256-mRxxZtWFgQ8v1szVq5g5+qVqa+OffoG1aHzGUiMMvT0=";
            };
            version = "2.3.0";
          });
          immich = final.overlay-unstable.immich;
          mautrix-whatsapp = final.overlay-compat.mautrix-whatsapp;
        })
      ];
    in
    {
      nixosConfigurations =
        let
          mkMode =
            mode: host:
            let
              host-nixpkgs = nixpkgs;
              host-home-manager = home-manager;
            in
            host-nixpkgs.lib.nixosSystem {
              # use system from config.localSystem
              # see https://github.com/NixOS/nixpkgs/blob/5297d584bcc5f95c8e87c631813b4e2ab7f19ecc/nixos/lib/eval-config.nix#L55
              system = null;
              pkgs = null;
              specialArgs = inputs;
              modules = [
                ./hosts/${host}/${mode}.nix
                ./modules/default.nix
                (
                  { config, ... }:
                  {
                    networking.hostName = "${host}";
                    # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
                    nix.registry.nixpkgs.flake = host-nixpkgs;
                    system.stateVersion = "24.05";
                    # record git revision (can be queried with `nixos-version --json)
                    system.configurationRevision = host-nixpkgs.lib.mkIf (self ? rev) self.rev;
                    nixpkgs = {
                      config.allowUnfree = true;
                      config.permittedInsecurePackages = [
                        # https://github.com/nix-community/nixd/issues/357
                        "nix-2.16.2"
                        # https://github.com/mautrix/go/issues/262
                        "olm-3.2.16"
                      ];
                      overlays = getSystemOverlays config.nixpkgs.hostPlatform.system config.nixpkgs.config;
                      # uncomment for cross compilation (https://github.com/NixOS/nix/issues/3843)
                      #buildPlatform.system = "cpu-os";
                    };
                    security.acme-eon.acceptTerms = true;
                  }
                )
                host-home-manager.nixosModule
                eilean.nixosModules.default
                agenix.nixosModules.default
              ];
            };
          readModes =
            dir:
            let
              files = builtins.readDir dir;
            in
            let
              filtered = nixpkgs.lib.attrsets.filterAttrs (
                n: v: v == "regular" && (n == "default.nix" || n == "minimal.nix")
              ) files;
            in
            let
              names = nixpkgs.lib.attrNames filtered;
            in
            builtins.map (f: nixpkgs.lib.strings.removeSuffix ".nix" f) names;
          mkModes =
            host: modes:
            builtins.map (mode: {
              name = "${host}${if mode == "default" then "" else "-${mode}"}";
              value = mkMode mode host;
            }) modes;
          mkHosts =
            hosts:
            let
              nestedList = builtins.map (host: mkModes host (readModes ./hosts/${host})) hosts;
            in
            let
              list = nixpkgs.lib.lists.flatten nestedList;
            in
            builtins.listToAttrs list;
          hosts = builtins.attrNames (builtins.readDir ./hosts);
        in
        mkHosts hosts;

      deploy = {
        user = "root";
        nodes = builtins.listToAttrs (
          builtins.map
            (
              name:
              let
                machine = self.nixosConfigurations.${name};
                system = machine.pkgs.system;
                pkgs = import nixpkgs { inherit system; };
                # nixpkgs with deploy-rs overlay but force the nixpkgs package
                deployPkgs = import nixpkgs {
                  inherit system;
                  overlays = [
                    deploy-rs.overlay
                    (self: super: {
                      deploy-rs = {
                        inherit (pkgs) deploy-rs;
                        lib = super.deploy-rs.lib;
                      };
                    })
                  ];
                };
              in
              {
                inherit name;
                value = {
                  # if we're on a different system build on the remote
                  #remoteBuild = machine.config.nixpkgs.hostPlatform.system == builtins.currentSystem;
                  remoteBuild = true;
                  sshUser = "root";
                  hostname = if name == "swan" then "eeg.cl.cam.ac.uk" else machine.config.networking.hostName;
                  profiles.system = {
                    user = "root";
                    path = deployPkgs.deploy-rs.lib.activate.nixos machine;
                  };
                };
              }
            )
            [
              "capybara"
              "duck"
              "elephant"
              "gecko"
              "owl"
              "shrew"
              "swan"
            ]
        );
      };

      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        modules = [ ./nix-on-droid/default.nix ];
        pkgs = import nixpkgs {
          overlays = getSystemOverlays "aarch64-linux" { };
          config.permittedInsecurePackages = [
            # https://github.com/nix-community/nixd/issues/357
            "nix-2.16.2"
          ];
        };
      };

      homeConfigurations = {
        rtg24 =
          let
            system = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${system};
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home/default.nix
              {
                nix.package = pkgs.nix;
                nixpkgs.overlays = getSystemOverlays system { };
                home.username = "rtg24";
                home.homeDirectory = "/home/rtg24";
                home.packages = with pkgs; [ home-manager ];
                custom = {
                  machineColour = "red";
                  nvim-lsps = true;
                };
              }
            ];
          };
      };

      legacyPackages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: {
        nixpkgs = import nixpkgs {
          inherit system;
          overlays = getSystemOverlays system { };
        };
      });

      formatter = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
        system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
