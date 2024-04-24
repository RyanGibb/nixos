{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    #home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.url = "github:RyanGibb/home-manager/fork";
    agenix.url = "github:ryantm/agenix";
    deploy-rs.url = "github:serokell/deploy-rs";
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-23.05";
    eon.url = "github:RyanGibb/eon";
    eilean.url = "github:RyanGibb/eilean-nix/main";
    ryan-website.url = "git+ssh://git@github.com/RyanGibb/website.git";
    alec-website.url = "github:alexanderhthompson/website";
    fn06-website.url = "github:RyanGibb/fn06";
    colour-guesser.url =
      "git+ssh://git@github.com/ryangibb/colour-guesser.git?ref=develop";
    i3-workspace-history.url = "github:RyanGibb/i3-workspace-history";
    hyperbib-eeg.url = "github:RyanGibb/hyperbib?ref=nixify";
    neovim.url =
      "github:neovim/neovim/f40df63bdca33d343cada6ceaafbc8b765ed7cc6?dir=contrib";
    nix-rpi5.url = "gitlab:vriska/nix-rpi5?ref=main";
    patrick-nixos.url = "github:patricoferris/nixos";

    # deduplicate flake inputs
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    eilean.inputs.eon.follows = "eon";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    ryan-website.inputs.nixpkgs.follows = "nixpkgs";
    alec-website.inputs.nixpkgs.follows = "nixpkgs";
    fn06-website.inputs.nixpkgs.follows = "nixpkgs";
    eon.inputs.nixpkgs.follows = "nixpkgs";
    colour-guesser.inputs.nixpkgs.follows = "nixpkgs";
    i3-workspace-history.inputs.nixpkgs.follows = "nixpkgs";
    hyperbib-eeg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager
    , agenix, deploy-rs, nix-on-droid, eon, eilean, fn06-website
    , i3-workspace-history, hyperbib-eeg, neovim, ... }@inputs:
    let
      getSystemOverlays = system: nixpkgsConfig:
        [
          (final: prev: {
            overlay-unstable = import nixpkgs-unstable {
              inherit system;
              # follow stable nixpkgs config
              config = nixpkgsConfig;
            };
            agenix = agenix.packages.${system}.default;
            eon = eon.defaultPackage.${system};
            mautrix-signal = final.overlay-unstable.mautrix-signal;
            i3-workspace-history =
              i3-workspace-history.packages.${system}.default;
            maildir-rank-addr =
              final.callPackage ./pkgs/maildir-rank-addr.nix { };
            # https://github.com/NixOS/nixpkgs/issues/86349#issuecomment-624489806
            aerc = (prev.callPackage
              "${prev.path}/pkgs/applications/networking/mailreaders/aerc/default.nix" {
                buildGoModule = args:
                  prev.buildGoModule (args // {
                    src = prev.fetchFromSourcehut {
                      owner = "~rjarry";
                      repo = "aerc";
                      rev = "930e50328c3a57faeec7fd23881e044257eda157";
                      hash =
                        "sha256-V1cjjJBAGqfBZIizAweMUYl7X3QorgLh/8J4HulmKAE=";
                    };
                    vendorHash =
                      "sha256-IzQKgNilBq53w41gNLXCd1BgYXW/aUuQQtFeKEI/dKw=";
                  });
              });
            # https://github.com/swaywm/sway/pull/7226
            sway-unwrapped = prev.callPackage ./pkgs/sway-im/package.nix {
              libdrm = final.overlay-unstable.libdrm;
              wlroots = prev.callPackage ./pkgs/wlroots/default.nix {
                # for libdrm >=2.4.120
                mesa = final.overlay-unstable.mesa;
                wayland-protocols = prev.wayland-protocols.overrideAttrs
                  (old: rec {
                    pname = "wayland-protocols";
                    version = "1.33";
                    src = prev.fetchurl {
                      url =
                        "https://gitlab.freedesktop.org/wayland/${pname}/-/releases/${version}/downloads/${pname}-${version}.tar.xz";
                      hash =
                        "sha256-lPDFCwkNbmGgP2IEhGexmrvoUb5OEa57NvZfi5jDljo=";
                    };
                  });
              };
            };
            neovim-unwrapped = if neovim.packages ? ${system} then
              neovim.packages.${system}.default
            else
              prev.neovim-unwrapped;
            # https://github.com/NixOS/nixpkgs/pull/291559
            libvpl = final.overlay-unstable.libvpl.overrideAttrs
              (_: { patches = [ ./pkgs/opengl-driver-lib.patch ]; });
            # https://github.com/jellyfin/jellyfin-media-player/issues/165#issuecomment-1966131861
            jellyfin-media-player = prev.jellyfin-media-player.overrideAttrs
              (old: {
                buildInputs =
                  (prev.lib.filter (input: input != prev.mpv) old.buildInputs)
                  ++ [
                    (prev.mpv-unwrapped.overrideAttrs (old: {
                      buildInputs =
                        (prev.lib.filter (input: input != prev.libva)
                          old.buildInputs) ++ [
                            (prev.libva.overrideAttrs (_: {
                              src = prev.fetchFromGitHub {
                                owner = "intel";
                                repo = "libva";
                                rev =
                                  "1b7d71f68b6ebc7f7c3b80e3eb6b3d888b0463e1";
                                hash =
                                  "sha256-Bufv8/8YAMvo6P/8HgPKaWXI7TCE/mf98MGeclT2XyA=";
                              };
                            }))
                          ];
                    }))
                  ];
              });
          })
        ];
    in rec {
      nixosConfigurations = let
        mkMode = mode: host:
          nixpkgs.lib.nixosSystem {
            # use system from config.localSystem
            # see https://github.com/NixOS/nixpkgs/blob/5297d584bcc5f95c8e87c631813b4e2ab7f19ecc/nixos/lib/eval-config.nix#L55
            system = null;
            pkgs = null;
            specialArgs = inputs;
            modules = [
              ./hosts/${host}/${mode}.nix
              ./modules/default.nix
              ({ config, ... }: {
                networking.hostName = "${host}";
                # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
                nix.registry.nixpkgs.flake = nixpkgs;
                system.stateVersion = "22.05";
                # record git revision (can be queried with `nixos-version --json)
                system.configurationRevision =
                  nixpkgs.lib.mkIf (self ? rev) self.rev;
                nixpkgs = {
                  config.allowUnfree = true;
                  config.permittedInsecurePackages = [
                    # obsidian
                    "electron-25.9.0"
                    # https://github.com/nix-community/nixd/issues/357
                    "nix-2.16.2"
                  ];
                  overlays =
                    getSystemOverlays config.nixpkgs.hostPlatform.system
                    config.nixpkgs.config;
                  # uncomment for cross compilation (https://github.com/NixOS/nix/issues/3843)
                  #buildPlatform.system = "cpu-os";
                };
              })
              home-manager.nixosModule
              eilean.nixosModules.default
              agenix.nixosModules.default
            ];
          };
        readModes = dir:
          let files = builtins.readDir dir;
          in let
            filtered = nixpkgs.lib.attrsets.filterAttrs (n: v:
              v == "regular" && (n == "default.nix" || n == "minimal.nix" || n
                == "sd-image.nix")) files;
          in let names = nixpkgs.lib.attrNames filtered;
          in builtins.map (f: nixpkgs.lib.strings.removeSuffix ".nix" f) names;
        mkModes = host: modes:
          builtins.map (mode: {
            name = "${host}${if mode == "default" then "" else "-${mode}"}";
            value = mkMode mode host;
          }) modes;
        mkHosts = hosts:
          let
            nestedList =
              builtins.map (host: mkModes host (readModes ./hosts/${host}))
              hosts;
          in let list = nixpkgs.lib.lists.flatten nestedList;
          in builtins.listToAttrs list;
        hosts = builtins.attrNames (builtins.readDir ./hosts);
      in mkHosts hosts;

      deploy = {
        user = "root";
        nodes = builtins.listToAttrs (builtins.map (name:
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
          in {
            inherit name;
            value = {
              # if we're on a different system build on the remote
              #remoteBuild = machine.config.nixpkgs.hostPlatform.system == builtins.currentSystem;
              remoteBuild = true;
              sshUser = "root";
              hostname = if name == "swan" then
                "eeg.cl.cam.ac.uk"
              else
                machine.config.networking.hostName;
              profiles.system = {
                user = "root";
                path = deployPkgs.deploy-rs.lib.activate.nixos machine;
              };
            };
          }) [ "capybara" "duck" "elephant" "gecko" "owl" "shrew" "swan" ]);
      };

      nixOnDroidConfigurations.default =
        nix-on-droid.lib.nixOnDroidConfiguration {
          modules = [ ./nix-on-droid/default.nix ];
          pkgs = import nixpkgs {
            overlays = getSystemOverlays "aarch64-linux" { };
            config.permittedInsecurePackages = [
              # https://github.com/nix-community/nixd/issues/357
              "nix-2.16.2"
            ];
          };
        };

      homeConfigurations.ryan = let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home/default.nix ];
      };

      legacyPackages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
        (system: {
          nixpkgs = nixpkgs.legacyPackages.${system};
          nixpkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
        });

      formatter = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
        (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
