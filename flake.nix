{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    agenix.url = "github:ryantm/agenix";
    deploy-rs.url = "github:serokell/deploy-rs";
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    eon.url = "github:RyanGibb/eon";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    alec-website.url = "github:alexanderhthompson/website";
    fn06-website.url = "github:RyanGibb/fn06";
    i3-workspace-history.url = "github:RyanGibb/i3-workspace-history";
    nix-rpi5.url = "gitlab:vriska/nix-rpi5?ref=main";
    nur.url = "github:nix-community/NUR/e9e77b7985ef9bdeca12a38523c63d47555cc89b";
    timewall.url = "github:bcyran/timewall/2.0.0";
    tangled.url = "git+https://tangled.sh/@tangled.sh/core";
    disko.url = "github:nix-community/disko";

    # deduplicate flake inputs
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    eilean.inputs.eon.follows = "eon";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    alec-website.inputs.nixpkgs.follows = "nixpkgs";
    fn06-website.inputs.nixpkgs.follows = "nixpkgs";
    eon.inputs.nixpkgs.follows = "nixpkgs";
    i3-workspace-history.inputs.nixpkgs.follows = "nixpkgs";
    nix-rpi5.inputs.nixpkgs.follows = "nixpkgs";
    nur.inputs.nixpkgs.follows = "nixpkgs";
    timewall.inputs.nixpkgs.follows = "nixpkgs";
    tangled.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      getSystemOverlays = system: nixpkgsConfig: [
        (final: prev: {
          overlay-unstable = import inputs.nixpkgs-unstable {
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
          opam = final.overlay-unstable.opam.overrideAttrs (_: rec {
            version = "2.4.0-alpha1";
            src = final.fetchurl {
              url = "https://github.com/ocaml/opam/releases/download/${version}/opam-full-${version}.tar.gz";
              sha256 = "sha256-kRGh8K5sMvmbJtSAEEPIOsim8uUUhrw11I+vVd/nnx4=";
            };
            patches = [ ./pkgs/opam-shebangs.patch ];
          });
          immich = final.overlay-unstable.immich;
          timewall = inputs.timewall.packages.${system}.default;
        })
        inputs.nur.overlays.default
      ];
    in
    {
      nixosConfigurations =
        let
          mkMode =
            mode: host:
            let
              host-nixpkgs = inputs.nixpkgs;
              host-home-manager = inputs.home-manager;
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
                    networking.hostName = host-nixpkgs.lib.mkDefault "${host}";
                    # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
                    nix.registry.nixpkgs.flake = host-nixpkgs;
                    system.stateVersion = "24.05";
                    # record git revision (can be queried with `nixos-version --json)
                    system.configurationRevision = host-nixpkgs.lib.mkIf (inputs.self ? rev) inputs.self.rev;
                    nixpkgs = {
                      config.allowUnfree = true;
                      config.permittedInsecurePackages = [
                        # https://github.com/nix-community/nixd/issues/357
                        "nix-2.16.2"
                        # https://github.com/mautrix/go/issues/262
                        "olm-3.2.16"
                        "aspnetcore-runtime-6.0.36"
                        "aspnetcore-runtime-wrapped-6.0.36"
                        "dotnet-sdk-6.0.428"
                        "dotnet-sdk-wrapped-6.0.428"
                      ];
                      overlays = getSystemOverlays config.nixpkgs.hostPlatform.system config.nixpkgs.config;
                      # uncomment for cross compilation (https://github.com/NixOS/nix/issues/3843)
                      #buildPlatform.system = "cpu-os";
                    };
                    security.acme-eon.acceptTerms = true;
                  }
                )
                host-home-manager.nixosModules.default
                inputs.eilean.nixosModules.default
                inputs.agenix.nixosModules.default
              ];
            };
          readModes =
            dir:
            let
              files = builtins.readDir dir;
            in
            let
              filtered = inputs.nixpkgs.lib.attrsets.filterAttrs (
                n: v: v == "regular" && (n == "default.nix" || n == "minimal.nix")
              ) files;
            in
            let
              names = inputs.nixpkgs.lib.attrNames filtered;
            in
            builtins.map (f: inputs.nixpkgs.lib.strings.removeSuffix ".nix" f) names;
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
              list = inputs.nixpkgs.lib.lists.flatten nestedList;
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
              host:
              let
                name = builtins.elemAt host 0;
                remote = builtins.elemAt host 1;
                machine = inputs.self.nixosConfigurations.${name};
                system = machine.pkgs.system;
                pkgs = import inputs.nixpkgs { inherit system; };
                # nixpkgs with deploy-rs overlay but force the nixpkgs package
                deployPkgs = import inputs.nixpkgs {
                  inherit system;
                  overlays = [
                    inputs.deploy-rs.overlay
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
                  remoteBuild = remote;
                  sshUser = "root";
                  hostname =
                    if name == "swan" then
                      "eeg.cl.cam.ac.uk"
                    else if name == "hippo" then
                      "hippo.freumh.org"
                    else
                      machine.config.networking.hostName;
                  profiles.system = {
                    user = "root";
                    path = deployPkgs.deploy-rs.lib.activate.nixos machine;
                  };
                };
              }
            )
            [
              # "capybara"
              ["duck" false]
              ["elephant" true]
              ["gecko" true]
              ["owl" false]
              ["hippo" true]
              # "shrew"
              ["swan" false]
            ]
        );
      };

      nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        modules = [ (import ./nix-on-droid/default.nix inputs) ];
        pkgs = import inputs.nixpkgs {
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
            pkgs = inputs.nixpkgs.legacyPackages.${system};
          in
          inputs.home-manager.lib.homeManagerConfiguration {
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
                };
              }
            ];
          };
        droid =
          let
            system = "aarch64-linux";
            pkgs = inputs.nixpkgs.legacyPackages.${system};
          in
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home/default.nix
              {
                nix.package = pkgs.nix;
                nixpkgs.overlays = getSystemOverlays system { };
                home.username = "droid";
                home.homeDirectory = "/home/droid";
                home.packages = with pkgs; [ home-manager ];
                custom = {
                  machineColour = "red";
                };
              }
            ];
          };
      };

      legacyPackages = inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed (system: {
        nixpkgs = import inputs.nixpkgs {
          inherit system;
          overlays = getSystemOverlays system { };
        };
      });

      formatter = inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed (
        system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
