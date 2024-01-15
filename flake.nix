{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-compat.url = "github:nixos/nixpkgs/39ddb6d";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    #home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.url = "github:RyanGibb/home-manager/fork";
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-23.05";
    eeww.url = "github:RyanGibb/eeww/nixos";
    eon.url = "github:RyanGibb/eon";
    eilean.url ="github:RyanGibb/eilean-nix/main";
    ryan-website.url = "git+ssh://git@github.com/RyanGibb/website.git";
    ryan-cv.url = "git+ssh://git@github.com/RyanGibb/cv.git";
    alec-website.url = "github:alexanderhthompson/website";
    fn06-website.url = "github:RyanGibb/fn06";
    colour-guesser.url = "git+ssh://git@github.com/ryangibb/colour-guesser.git?ref=develop";
    matrix-appservices.url = "gitlab:coffeetables/nix-matrix-appservices";
    kmonad.url = "github:kmonad/kmonad/?dir=nix";
    i3-workspace-history.url = "github:RyanGibb/i3-workspace-history";
    hyperbib-eeg.url = "github:RyanGibb/hyperbib?ref=nixify";

    # deduplicate flake inputs
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    ryan-cv.inputs.nixpkgs.follows = "nixpkgs";
    ryan-website.inputs.nixpkgs.follows = "nixpkgs";
    alec-website.inputs.nixpkgs.follows = "nixpkgs";
    fn06-website.inputs.nixpkgs.follows = "nixpkgs";
    eeww.inputs.nixpkgs.follows = "nixpkgs";
    eon.inputs.nixpkgs.follows = "nixpkgs";
    colour-guesser.inputs.nixpkgs.follows = "nixpkgs";
    matrix-appservices.inputs.nixpkgs.follows = "nixpkgs";
    kmonad.inputs.nixpkgs.follows = "nixpkgs";
    i3-workspace-history.inputs.nixpkgs.follows = "nixpkgs";
    hyperbib-eeg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-compat,
    nixos-hardware,
    home-manager,
    nix-on-droid,
    eeww,
    eon,
    eilean,
    fn06-website,
    matrix-appservices,
    kmonad,
    i3-workspace-history,
    hyperbib-eeg,
    ...
  }@inputs: rec {
    nixosConfigurations =
      let
        hosts = builtins.attrNames (builtins.readDir ./hosts);
        getSystemOverlays = system: nixpkgsConfig:
          [
            (final: prev: {
              overlay-unstable = import nixpkgs-unstable {
                inherit system;
                # follow stable nixpkgs config
                config = nixpkgsConfig;
              };
              overlay-compat = import nixpkgs-compat {
                inherit system;
                config = nixpkgsConfig;
              };
              "eeww" = eeww.defaultPackage.${system};
              "eon" = eon.defaultPackage.${system};
              "mautrix-whatsapp" = prev.callPackage ./pkgs/mautrix-whatsapp.nix { };
              "mautrix-facebook" = prev."mautrix-facebook".overrideAttrs (_: {
                buildInputs = [ prev.python3.pkgs.aiosqlite ];
              });
              "mautrix-instagram" = final.callPackage ./pkgs/mautrix-instagram.nix { };
              "i3-workspace-history" = i3-workspace-history.packages.${system}.default;
              "maildir-rank-addr" = final.callPackage ./pkgs/maildir-rank-addr.nix { };
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
                    # obsidian
                    config.permittedInsecurePackages = [
                      "electron-25.9.0"
                    ];
                    overlays = getSystemOverlays config.nixpkgs.hostPlatform.system config.nixpkgs.config;
                    # uncomment for cross compilation (https://github.com/NixOS/nix/issues/3843)
                    #buildPlatform.system = "cpu-os";
                  };
                })
                home-manager.nixosModule
                eilean.nixosModules.default
                eon.nixosModules.default
                matrix-appservices.nixosModule
                kmonad.nixosModules.default
                hyperbib-eeg.nixosModules.default
              ];
            };
        mkHosts = hosts: nixpkgs.lib.genAttrs hosts (mkHost "default");
        mkModeHosts = mode: hosts:
          (builtins.listToAttrs (builtins.map (host: { name = "${host}-${mode}"; value = mkHost mode host; } ) hosts));
      in mkHosts hosts // mkModeHosts "minimal" hosts;

    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      modules = [ ./nix-on-droid/default.nix ];
    };

    legacyPackages =
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system:
        nixpkgs.legacyPackages.${system}
      );
    };
}
