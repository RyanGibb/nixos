{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-compat.url = "github:nixos/nixpkgs/39ddb6d";
    nixpkgs-logseq.url = "github:nixos/nixpkgs/998ca7e";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    patchelf.url = "github:nixos/patchelf/ea2fca765c";
    eeww.url = "github:RyanGibb/eeww/nixos";
    aeon.url = "github:RyanGibb/aeon";
    wallpapers = {
      url ="git+ssh://git@git.freumh.org/ryan/wallpapers.git?ref=main";
      flake = false;
    };
    eilean.url ="git+https://git@git.freumh.org/ryan/eilean-nix.git?ref=main";
    # eilean.url ="github:RyanGibb/eilean-nix/main";
    ryan-website.url = "git+https://git@git.freumh.org/ryan/website.git";
    ryan-cv.url = "git+ssh://git@git.freumh.org/ryan/cv.git";
    ryan-website.inputs.cv.follows = "ryan-cv";
    # ryan-website.url = "github:RyanGibb/website";
    twitcher.url = "git+https://git@git.freumh.org/ryan/twitcher.git";
    # twitcher.url = "github:RyanGibb/twitcher";
    colour-guesser.url = "git+ssh://git@github.com/ryangibb/colour-guesser.git?ref=develop";
    matrix-appservices.url = "gitlab:coffeetables/nix-matrix-appservices";
    mautrix-signal = {
      url = "github:Jaffex/signal/6b4b07";
      flake = false;
    };
    mautrix-facebook = {
      url = "github:eyJhb/mautrix-facebook/spaces-support";
      flake = false;
    };

    # deduplicate flake inputs
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ryan-cv.inputs.nixpkgs.follows = "nixpkgs";
    ryan-website.inputs.nixpkgs.follows = "nixpkgs";
    twitcher.inputs.nixpkgs.follows = "nixpkgs";
    patchelf.inputs.nixpkgs.follows = "nixpkgs";
    eeww.inputs.nixpkgs.follows = "nixpkgs";
    aeon.inputs.nixpkgs.follows = "nixpkgs";
    colour-guesser.inputs.nixpkgs.follows = "nixpkgs";
    matrix-appservices.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-compat,
    nixpkgs-logseq,
    nixos-hardware,
    home-manager,
    patchelf,
    eeww,
    aeon,
    wallpapers,
    eilean,
    ryan-website,
    twitcher,
    colour-guesser,
    matrix-appservices,
    mautrix-signal,
    mautrix-facebook,
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
                # follow stable nixpkgs config
                config = nixpkgsConfig;
              };
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
              "colour-guesser" = colour-guesser.packages.${system}.default;
              # can uncomment if want to use patchelf-rafi elsewhere
              #"patchelf" = patchelf.packages.${system}.patchelf;
              # "cctk" = final.callPackage ./pkgs/cctk/default.nix { };
              "cctk" = prev.callPackage ./pkgs/cctk/default.nix { patchelf = patchelf.packages.${system}.patchelf; };
              "eeww" = eeww.defaultPackage.${system};
              "aeon" = aeon.defaultPackage.${system};
              "mautrix-whatsapp" = prev.callPackage ./pkgs/mautrix-whatsapp.nix { };
              "mautrix-signal" = prev."mautrix-signal".overrideAttrs (_: {
                src = mautrix-signal;
                buildInputs = [ prev.python3.pkgs.aiosqlite ];
              });
              "mautrix-facebook" = prev."mautrix-facebook".overrideAttrs (_: {
                src = mautrix-facebook;
                buildInputs = [ prev.python3.pkgs.aiosqlite ];
              });
              "mautrix-instagram" = final.overlay-unstable.callPackage ./pkgs/mautrix-instagram.nix { };
              "element-desktop" = final.overlay-compat.element-desktop;
              "logseq" =
                let pkgs = import nixpkgs-logseq {
                  inherit system;
                  config = nixpkgsConfig;
                }; in pkgs.logseq.overrideAttrs (oldAttrs: {
                  postFixup = ''
                    makeWrapper ${pkgs.electron_20}/bin/electron $out/bin/${oldAttrs.pname} \
                      --set "LOCAL_GIT_DIRECTORY" ${pkgs.git} \
                      --add-flags $out/share/${oldAttrs.pname}/resources/app \
                      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
                      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ prev.stdenv.cc.cc.lib ]}"
                  '';
              });
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
                    config.permittedInsecurePackages = [
                      "electron-20.3.11"
                    ];
                    overlays = getSystemOverlays config.nixpkgs.hostPlatform.system config.nixpkgs.config;
                    # uncomment for cross compilation (https://github.com/NixOS/nix/issues/3843)
                    #buildPlatform.system = "cpu-os";
                  };
                })
                home-manager.nixosModule
                eilean.nixosModules.default
                ryan-website.nixosModules.default
                twitcher.nixosModules.default
                colour-guesser.nixosModules.default
                aeon.nixosModules.default
                matrix-appservices.nixosModule
              ];
            };
        mkHosts = hosts: nixpkgs.lib.genAttrs hosts (mkHost "default");
        mkModeHosts = mode: hosts:
          (builtins.listToAttrs (builtins.map (host: { name = "${host}-${mode}"; value = mkHost mode host; } ) hosts));
      in mkHosts hosts // mkModeHosts "minimal" hosts;

    legacyPackages =
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: {
        stable = nixpkgs.legacyPackages.${system};
      }) //
      nixpkgs-unstable.lib.genAttrs nixpkgs-unstable.lib.systems.flakeExposed (system: {
        unstable = nixpkgs-unstable.legacyPackages.${system};
      });

    packages.x86_64-linux.cctk =
      with import nixpkgs { system = "x86_64-linux"; };
      (pkgs.callPackage ./pkgs/cctk/default.nix { patchelf = patchelf.packages.${system}.patchelf; });
    };
}
