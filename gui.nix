{ pkgs, ... }:

{
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
    users.ryan = import ./home.nix;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (
      builtins.fetchTarball {
        url = "https://github.com/nix-community/NUR/archive/526d47ce95bd4d5e041a4fd3ffb831183d8654fe.tar.gz";
        sha256 = "1v9q6kqcm331x2kca6a9grc0rkxawbl7hn3csbjicjm0v1cc4liq";
      }
    ) { inherit pkgs; };
  };

  environment.systemPackages = with pkgs; [
    firefox
    chromium
    thunderbird
    element-desktop
    signal-desktop
    zotero
    obsidian
    spotify
    gparted
    vscodium
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
  ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      jq
      swaylock
      swayidle
      wl-clipboard
      clipman
      wtype
      playerctl
      brightnessctl
      xdg-utils
      gammastep
      waybar
      alacritty
      mako
      libnotify
      wofi
      wofi-emoji
      gnome.zenity
      feh
      gnome.networkmanagerapplet
      wdisplays
      pavucontrol
      (xfce.thunar.override { thunarPlugins = with xfce; [
        thunar-archive-plugin
        xfconf
      ]; })
      gnome.file-roller
      # https://discourse.nixos.org/t/sway-wm-configuration-polkit-login-manager/3857/6
      polkit_gnome
      wf-recorder
      grim
      slurp
      swappy
      glib
    ];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    gtkUsePortal = false;
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
    # for projects/cv latex package fontawesome
    font-awesome_4
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-13.6.9"
  ];

  # thunar
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  # thunar thumbnail support for images
  services.tumbler.enable = true;

  services.geoclue2.enableDemoAgent = true;

  programs.kdeconnect.enable = true;

  system.stateVersion = "21.11";
}
