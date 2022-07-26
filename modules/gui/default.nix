{ pkgs, ... }:

let
  unstable = import (builtins.fetchTarball {
    name = "nixos-unstable-2022-05-27";
    url = "https://github.com/nixos/nixpkgs/archive/5ce6597eca7d7b518c03ecda57d45f9404b5e060.tar.gz";
    sha256 = "1hs1lnnbp1dky3nfp7xlricpp5c63sr46jyrnvykci8bl8jnxnl3";
  }) { config = { allowUnfree = true; }; };
in {
  networking.networkmanager.enable = true;
  programs.nm-applet = {
    enable = true;
    indicator = true;
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

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

  environment.systemPackages = with pkgs; [
    jq
    playerctl
    brightnessctl
    xdg-utils
    gnome.zenity
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

    (firefox.override {
      cfg = {
        enableTridactylNative = true;
      };
    })
    tridactyl-native
    chromium
    thunderbird
    element-desktop
    signal-desktop
    unstable.zotero
    unstable.obsidian
    spotify
    gparted
    unstable.vscodium
    vlc
    gimp
    go
    texlive.combined.scheme-full
    evince
    pdfpc
    calibre
    transmission
    transmission-gtk
    drive
    libreoffice
    obs-studio
    # https://nixos.wiki/wiki/PipeWire#pactl_not_found
    pulseaudio

    xournalpp
    inkscape
  ];

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
    # for projects/cv latex package fontawesome
    font-awesome
    source-code-pro
    aileron
    vistafonts
  ];

  # thunar
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  # thunar thumbnail support for images
  services.tumbler.enable = true;

  programs.kdeconnect.enable = true;
}
