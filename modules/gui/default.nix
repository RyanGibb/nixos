{
  config,
  i3-workspace-history,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.gui;
  plangothic = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "plangothic";
    version = "2.9.5792";
    srcs = [
      (pkgs.fetchurl {
        url = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/download/V${version}/PlangothicP1-Regular.ttf";
        sha256 = "0qyaxg3kgb7dlvqpdjld6nj5mdcqcid7yhxgry8z4lqrv6y4abdc";
      })
      (pkgs.fetchurl {
        url = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/download/V${version}/PlangothicP2-Regular.ttf";
        sha256 = "1jf0l75zjcj8c5ysfs918gr4i4n5dgrqwr924vl2ca30cjz6icrs";
      })
    ];
    sourceRoot = ".";
    dontUnpack = true;
    installPhase = ''
      install -Dm444 ${builtins.elemAt srcs 0} $out/share/fonts/truetype/PlangothicP1-Regular.ttf
      install -Dm444 ${builtins.elemAt srcs 1} $out/share/fonts/truetype/PlangothicP2-Regular.ttf
    '';
  };
in
{
  options.custom.gui.enable = lib.mkOption {
    type = lib.types.bool;
    default = cfg.i3 || cfg.sway || cfg.kde;
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.custom.username} =
      { config, ... }:
      {
        config.custom.gui.enable = true;
      };

    services.displayManager.ly.settings.session_log = ".local/state/ly-session.log";

    networking.networkmanager.enable = true;

    i18n = {
      defaultLocale = "en_GB.UTF-8";
    };
    console = {
      font = "Lat2-Terminus16";
      keyMap = "uk";
    };

    # Needed for Keychron K2
    boot.extraModprobeConfig = ''
      options hid_apple fnmode=2
      options i915 enable_psr=0
      options btusb enable_autosuspend=n
    '';
    boot.kernelModules = [ "hid-apple" ];

    services.xserver = {
      excludePackages = with pkgs; [ xterm ];
      displayManager.startx.enable = true;
      xkb.layout = "gb";
    };

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          FastConnectable = true;
          ReconnectAttempts = 7;
          ReconnectIntervals = "1,2,3";
          Experimental = "true";
        };
      };
    };

    environment.systemPackages =
      with pkgs;
      let
        desktopEntries = [
          (pkgs.makeDesktopItem {
            name = "feh.desktop";
            desktopName = "feh";
            exec = "feh --scale-down --auto-zoom";
            icon = "feh";
          })
        ];
      in
      [
        jq
        playerctl
        brightnessctl
        bluetuith
        pulsemixer
        xdg-utils
        yad
        networkmanagerapplet
        pavucontrol
        # https://discourse.nixos.org/t/sway-wm-configuration-polkit-login-manager/3857/6
        polkit_gnome
        glib
        feh
        libnotify
        # https://nixos.wiki/wiki/PipeWire#pactl_not_found
        pulseaudio
        tridactyl-native
        vlc
        swaybg
      ]
      ++ desktopEntries;

    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.droid-sans-mono
      plangothic
      libertine
    ];

    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    services.gvfs.enable = true;
    services.tumbler.enable = true; # thumbnails

    # sets $WORLDLIST for `dict`
    environment.wordlist.enable = true;
  };
}
