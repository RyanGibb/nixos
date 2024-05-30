{ pkgs, config, lib, ... }:

let cfg = config.custom.gui;
in {
  options.custom.gui.enable = lib.mkOption {
    type = lib.types.bool;
    default = cfg.i3 || cfg.sway || cfg.kde;
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${config.custom.username} = { config, ... }: {
      config.custom.gui.enable = true;
    };

    networking.networkmanager.enable = true;

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
    services.blueman.enable = true;

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
        (xfce.thunar.override {
          thunarPlugins = with xfce; [ thunar-archive-plugin xfconf ];
        })
        # https://discourse.nixos.org/t/sway-wm-configuration-polkit-login-manager/3857/6
        polkit_gnome
        glib
        feh
        libnotify
        # https://nixos.wiki/wiki/PipeWire#pactl_not_found
        pulseaudio
        (firefox.override {
          nativeMessagingHosts = with pkgs; [ tridactyl-native ];
        })
        tridactyl-native
        vlc
        i3-workspace-history
      ] ++ desktopEntries;

    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
      wqy_zenhei
    ];

    # thunar
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    # thunar thumbnail support for images
    services.tumbler.enable = true;

    # sets $WORLDLIST for `dict`
    environment.wordlist.enable = true;
  };
}
