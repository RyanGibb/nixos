{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    #home-manager.url = "github:nix-community/home-manager";
    home-manager.url = "github:RyanGibb/home-manager/fork-unstable";
    agenix.url = "github:ryantm/agenix";
    nix-on-droid.url = "github:nix-community/nix-on-droid";
    eeww.url = "github:RyanGibb/eeww/nixos";
    eon.url = "github:RyanGibb/eon";
    eilean.url ="github:RyanGibb/eilean-nix/main";
    ryan-website.url = "git+ssh://git@github.com/RyanGibb/website.git";
    alec-website.url = "github:alexanderhthompson/website";
    fn06-website.url = "github:RyanGibb/fn06";
    colour-guesser.url = "git+ssh://git@github.com/ryangibb/colour-guesser.git?ref=develop";
    i3-workspace-history.url = "github:RyanGibb/i3-workspace-history";
    hyperbib-eeg.url = "github:RyanGibb/hyperbib?ref=nixify";
    neovim.url = "github:neovim/neovim/f40df63bdca33d343cada6ceaafbc8b765ed7cc6?dir=contrib";
    nix-rpi5.url = "gitlab:vriska/nix-rpi5?ref=main";

    # deduplicate flake inputs
    eilean.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
    ryan-website.inputs.nixpkgs.follows = "nixpkgs";
    alec-website.inputs.nixpkgs.follows = "nixpkgs";
    fn06-website.inputs.nixpkgs.follows = "nixpkgs";
    eeww.inputs.nixpkgs.follows = "nixpkgs";
    eon.inputs.nixpkgs.follows = "nixpkgs";
    colour-guesser.inputs.nixpkgs.follows = "nixpkgs";
    i3-workspace-history.inputs.nixpkgs.follows = "nixpkgs";
    hyperbib-eeg.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    agenix,
    nix-on-droid,
    eeww,
    eon,
    eilean,
    fn06-website,
    i3-workspace-history,
    hyperbib-eeg,
    neovim,
    ...
  }@inputs:
    let
      getSystemOverlays = system: nixpkgsConfig:
        [
          (final: prev: {
            agenix = agenix.packages.${system}.default;
            eeww = eeww.defaultPackage.${system};
            eon = eon.defaultPackage.${system};
            i3-workspace-history = i3-workspace-history.packages.${system}.default;
            maildir-rank-addr = final.callPackage ./pkgs/maildir-rank-addr.nix { };
            # https://github.com/NixOS/nixpkgs/issues/86349#issuecomment-624489806
            aerc = (prev.callPackage "${prev.path}/pkgs/applications/networking/mailreaders/aerc/default.nix" {
              buildGoModule = args: prev.buildGoModule (args // {
                 src = prev.fetchFromSourcehut {
                  owner = "~rjarry";
                  repo = "aerc";
                  rev = "930e50328c3a57faeec7fd23881e044257eda157";
                  hash = "sha256-V1cjjJBAGqfBZIizAweMUYl7X3QorgLh/8J4HulmKAE=";
                };
                vendorHash = "sha256-IzQKgNilBq53w41gNLXCd1BgYXW/aUuQQtFeKEI/dKw=";
              });
            });
            # https://github.com/swaywm/sway/pull/7226
            sway-unwrapped = prev.callPackage ./pkgs/sway-im/package.nix {
              libdrm = prev.libdrm;
              wlroots = prev.callPackage ./pkgs/wlroots/default.nix {
                # for libdrm >=2.4.120
                mesa = prev.mesa;
                wayland-protocols = prev.wayland-protocols.overrideAttrs (old: rec {
                  pname = "wayland-protocols";
                  version = "1.33";
                  src = prev.fetchurl {
                    url = "https://gitlab.freedesktop.org/wayland/${pname}/-/releases/${version}/downloads/${pname}-${version}.tar.xz";
                    hash = "sha256-lPDFCwkNbmGgP2IEhGexmrvoUb5OEa57NvZfi5jDljo=";
                  };
                });
              };
            };
            neovim-unwrapped = neovim.packages.${system}.default;
            # https://github.com/NixOS/nixpkgs/pull/291559
            libvpl = prev.libvpl.overrideAttrs (_: {
              patches = [ ./pkgs/opengl-driver-lib.patch ];
            });
            # https://github.com/jellyfin/jellyfin-media-player/issues/165#issuecomment-1966131861
            jellyfin-media-player = prev.jellyfin-media-player.overrideAttrs (old: {
              buildInputs =
                (prev.lib.filter (input: input != prev.mpv) old.buildInputs) ++ [
                (prev.mpv-unwrapped.overrideAttrs (old: {
                  buildInputs =
                    (prev.lib.filter (input: input != prev.libva) old.buildInputs) ++ [
                    (prev.libva.overrideAttrs (_: {
                      src = prev.fetchFromGitHub {
                        owner = "emersion";
                        repo = "libva";
                        rev = "linux-dmabuf";
                        hash = "sha256-Bufv8/8YAMvo6P/8HgPKaWXI7TCE/mf98MGeclT2XyA=";
                      };
                    }))
                  ];
                }))
              ];
            });
            waybar = prev.waybar.override {
              wireplumber = prev.wireplumber.overrideAttrs rec {
                version = "0.4.17";
                src = prev.fetchFromGitLab {
                  domain = "gitlab.freedesktop.org";
                  owner = "pipewire";
                  repo = "wireplumber";
                  rev = version;
                  hash = "sha256-vhpQT67+849WV1SFthQdUeFnYe/okudTQJoL3y+wXwI=";
                };
              };
            };
          })
        ];
  in rec {
    nixosConfigurations =
      let
        mkMode = mode: host:
          nixpkgs.lib.nixosSystem {
            # use system from config.localSystem
            # see https://github.com/NixOS/nixpkgs/blob/5297d584bcc5f95c8e87c631813b4e2ab7f19ecc/nixos/lib/eval-config.nix#L55
            system = null;
            pkgs = null;
            specialArgs = inputs;
            modules =
              [
                ./hosts/${host}/${mode}.nix
                ./modules/default.nix
                ({ config, ... }: {
                  networking.hostName = "${host}";
                  # pin nix command's nixpkgs flake to the system flake to avoid unnecessary downloads
                  nix.registry.nixpkgs.flake = nixpkgs;
                  system.stateVersion = "22.05";
                  # record git revision (can be queried with `nixos-version --json)
                  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
                  nixpkgs = {
                    config.allowUnfree = true;
                    config.permittedInsecurePackages = [
                      # obsidian
                      "electron-25.9.0"
                      # https://github.com/nix-community/nixd/issues/357
                      "nix-2.16.2"
                    ];
                    overlays = getSystemOverlays config.nixpkgs.hostPlatform.system config.nixpkgs.config;
                    # uncomment for cross compilation (https://github.com/NixOS/nix/issues/3843)
                    #buildPlatform.system = "cpu-os";
                  };
                })
                home-manager.nixosModule
                eilean.nixosModules.default
                eon.nixosModules.default
                hyperbib-eeg.nixosModules.default
                agenix.nixosModules.default
              ];
            };
        readModes = dir:
          let files = builtins.readDir dir; in
          let filtered = nixpkgs.lib.attrsets.filterAttrs (n: v:
            v == "regular" && (
              n == "default.nix" ||
              n == "minimal.nix" ||
              n == "sd-image.nix"
            )
          ) files; in
          let names = nixpkgs.lib.attrNames filtered; in
          builtins.map (f: nixpkgs.lib.strings.removeSuffix ".nix" f) names;
        mkModes = host: modes:
          builtins.map (mode:
            {
              name = "${host}${if mode == "default" then "" else "-${mode}"}";
              value = mkMode mode host;
            }
          ) modes;
        mkHosts = hosts:
        let nestedList = builtins.map (host: mkModes host (readModes ./hosts/${host})) hosts; in
          let list = nixpkgs.lib.lists.flatten nestedList; in
          builtins.listToAttrs list;
        hosts = builtins.attrNames (builtins.readDir ./hosts);
      in mkHosts hosts;

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

    legacyPackages =
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system:
        nixpkgs.legacyPackages.${system}
      );
  };
}
