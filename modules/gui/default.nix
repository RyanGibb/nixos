{
  pkgs,
  config,
  lib,
  i3-workspace-history,
  ...
}:

let
  cfg = config.custom.gui;
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

    networking.networkmanager.enable = true;

    i18n = {
      defaultLocale = "en_GB.UTF-8";
      inputMethod = {
        enable = true;
        type = "fcitx5";
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

    hardware.bluetooth.enable = true;

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
        timewall
        swaybg
      ]
      ++ desktopEntries;

    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      nerd-fonts.droid-sans-mono
      wqy_zenhei
      libertine
    ];

    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
    };
    services.gvfs.enable = true;
    # thumbnail support for images
    services.tumbler.enable = true;

    # sets $WORLDLIST for `dict`
    environment.wordlist.enable = true;
  };
}
