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

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  nixpkgs.config.allowUnfree = true;

  home-manager = {
    useGlobalPkgs = true;
    users.ryan = import ./home.nix;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (
      builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz"
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
  ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      jq
      swaylock
      swayidle
      wtype
      playerctl
      brightnessctl
      xdg-utils
      gammastep
      waybar
      alacritty
      mako
      wofi
      gnome.zenity
      feh
      copyq
      gnome.networkmanagerapplet
      wdisplays
      pavucontrol
      xfce.thunar
      xfce.xfconf # Needed to save the preferences
      xfce.exo # Used by default for `open terminal here`, but can be changed
      rofimoji
      # https://discourse.nixos.org/t/sway-wm-configuration-polkit-login-manager/3857/6
      polkit_gnome
      wf-recorder
      grim
      slurp
    ];
  };

  services.pipewire.enable = true;
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
      gtkUsePortal = true;
    };
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
    font-awesome
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

