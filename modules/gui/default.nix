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

    nixpkgs.config.allowUnfree = true;

    home-manager = { useGlobalPkgs = true; };

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
        gnome.file-roller
        gnome.cheese
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
        chromium
        gparted
        vlc
        i3-workspace-history
      ] ++ desktopEntries;

    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
      source-code-pro
      aileron
      vistafonts
      wqy_zenhei
    ];

    # thunar
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    # thunar thumbnail support for images
    services.tumbler.enable = true;

    # ZSA Moonlander udev rules
    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "zsa-udev-rules";
        text = ''
          # Rules for Oryx web flashing and live training
          KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
          KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

          # Legacy rules for live training over webusb (Not needed for firmware v21+)
            # Rule for all ZSA keyboards
            SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
            # Rule for the Moonlander
            SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
            # Rule for the Ergodox EZ
            SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
            # Rule for the Planck EZ
            SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"

          # Wally Flashing rules for the Ergodox EZ
          ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
          ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
          KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

          # Wally Flashing rules for the Moonlander and Planck EZ
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
        '';
        destination = "/lib/udev/rules.d/50-zsa.rules";
      })
    ];

    # sets $WORLDLIST
    environment.wordlist.enable = true;
  };
}
