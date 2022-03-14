{ pkgs, ... }:

{
  imports = [
    ./common.nix
    <home-manager/nixos> 
  ];

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    extraEntries = ''
      menuentry 'Arch Linux' {
        configfile (hd0,7)/boot/grub/grub.cfg
      }
    '';
  };

  networking.hostName = "dell-xps";

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

  networking.useDHCP = false;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  users.users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  users.users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";

  networking.firewall.allowedTCPPorts = [
    53 # ssh
    631 # printing
  ]; 
  networking.firewall.allowedUDPPorts = [
    53 # mosh
    631 # printing
  ];
  
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Needed for Keychron K2
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
  boot.kernelModules = [ "hid-apple" ];

  boot.supportedFilesystems = [ "ntfs" ];

  services.printing = {
    enable = true;
    browsing = true;
    defaultShared = true;
  };
  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns = true;
  };

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
    firefox-wayland
    chromium
    thunderbird-wayland
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
      fusuma
      kanshi
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
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  services.geoclue2.enableDemoAgent = true;

  users.users.ryan.extraGroups = [ "input" ];

  programs.kdeconnect.enable = true;

  system.stateVersion = "21.11";
}

