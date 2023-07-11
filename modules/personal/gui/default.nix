{ pkgs, config, lib, ... }:

let cfg = config.personal.gui; in
{
  options.personal.gui.enable = lib.mkOption {
    type = lib.types.bool;
    default = cfg.i3 || cfg.sway || cfg.kde;
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
    programs.nm-applet = {
      enable = true;
      indicator = true;
    };

    i18n = {
      defaultLocale = "en_GB.UTF-8";
      inputMethod = {
        enabled = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-rime
          fcitx5-chinese-addons
          fcitx5-m17n
        ];
      };
    };
    console = {
      font = "Lat2-Terminus16";
      keyMap = "uk";
    };

    # Needed for Keychron K2
    boot.extraModprobeConfig = ''
      options hid_apple fnmode=2
      options i915 enable_psr=0
    '';
    boot.kernelModules = [ "hid-apple" ];

    services.xserver = {
      desktopManager.xterm.enable = false;
      displayManager.startx.enable = true;
      layout = "gb";
    };

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    nixpkgs.config.allowUnfree = true;

    home-manager = {
      useGlobalPkgs = true;
    };

    environment.systemPackages = with pkgs;
      let
      desktopEntries = [
        (pkgs.makeDesktopItem {
          name = "feh.desktop";
          desktopName = "feh";
          exec = "feh --scale-down --auto-zoom";
          icon = "feh";
        })
      ];
    in [
      jq
      playerctl
      brightnessctl
      xdg-utils
      yad
      networkmanagerapplet
      pavucontrol
      (xfce.thunar.override { thunarPlugins = with xfce; [
        thunar-archive-plugin
        xfconf
      ]; })
      gnome.file-roller
      # https://discourse.nixos.org/t/sway-wm-configuration-polkit-login-manager/3857/6
      polkit_gnome
      glib
      feh
      libnotify

      # https://nixos.wiki/wiki/PipeWire#pactl_not_found
      pulseaudio

      (firefox.override {
        cfg = {
          enableTridactylNative = true;
        };
      })
      tridactyl-native
      chromium
      gparted
      vlc
      (vscode-with-extensions.override {
        vscode = vscodium;
        vscodeExtensions = with vscode-extensions; [
          bbenoist.nix
          #asvetliakov.vscode-neovim
          #eamodio.gitlens
          james-yu.latex-workshop
          ocamllabs.ocaml-platform
          streetsidesoftware.code-spell-checker
          #vscodevim.vim
          # anwar.papyrus-pdf
          # ctf0.macros
          # znck.grammarly
          vscode-extensions.jdinhlife.gruvbox
        ];
      })
    ] ++ desktopEntries;

    fonts.fonts = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
      source-code-pro
      aileron
      vistafonts
      wqy_zenhei
    ];

    # thunar thumbnail support for images
    services.tumbler.enable = true;
  };
}
