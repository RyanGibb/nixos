{ pkgs, lib, config, ... }:

{
  imports = [ ./hardware-configuration.nix ./backups.nix ];

  custom = {
    enable = true;
    tailscale = true;
    laptop = true;
    printing = true;
    gui.i3 = true;
    gui.sway = true;
    ocaml = true;
    workstation = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
    zsa = true;
  };

  home-manager.users.${config.custom.username} = {
    services.kdeconnect.enable = true;
    services.spotifyd = {
      enable = true;
      settings.global = {
        username = "ryangibb321@gmail.com";
        password_cmd = "pass show spotify/ryangibb321@gmail.com";
      };
    };
    custom = {
      machineColour = "blue";
      nvim-lsps = true;
      mail.enable = true;
      calendar.enable = true;
      battery.enable = true;
    };
    home.sessionVariables = {
      LEDGER_FILE = ''~/vault/ledger/`date "+%Y"`.ledger'';
    };
    programs.git.extraConfig.commit.gpgSign = true;
  };

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  environment.systemPackages = with pkgs; [
    dell-command-configure
    gnome.file-roller
    unzip
    gnome.cheese
    gparted
    chromium
    calibre
    zotero
    element-desktop
    iamb
    spotify
    gimp
    (python3.withPackages (p: with p; [ numpy matplotlib pandas ]))
    lsof
    gthumb
    restic
    mosquitto
    texlive.combined.scheme-full
    typst
    evince
    pdfpc
    krop
    transmission
    transmission-gtk
    libreoffice
    obs-studio
    xournalpp
    inkscape
    kdenlive
    tor-browser-bundle-bin
    ffmpeg
    audio-recorder
    speechd
    deploy-rs
    nix-prefetch-git
    tcpdump
    pandoc
    w3m
    ranger
    bluetuith
    powertop
    toot
    ledger
    virtualbox
    llm
    (writeShellScriptBin "q" ''
      llm -m 4 "$*"
    '')
    (writeShellScriptBin "qc" ''
      llm -m 4 "$*" -c
    '')
    ddcutil
    anki
    (aspellWithDicts (ps: with ps; [en]))
  ];

  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;

  virtualisation.docker.enable = true;
  users.users.ryan.extraGroups = [ "docker" ];

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "ryan" ];

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  programs.steam.enable = true;

  security.sudo.extraConfig = ''
    Defaults !tty_tickets
  '';

  # sometimes I want to keep the cache for operating without internet
  nix.gc.automatic = lib.mkForce false;

  # for CL VPN
  networking.networkmanager.enableStrongSwan = true;

  services = {
    syncthing = {
      enable = true;
      user = config.custom.username;
      dataDir = "/home/ryan/syncthing";
      configDir = "/home/ryan/.config/syncthing";
    };
  };

  networking.hostId = "e768032f";

  #system.includeBuildDependencies = true;
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;

  # https://github.com/NixOS/nixpkgs/issues/330685
  boot.extraModprobeConfig = ''
    options snd-hda-intel dmic_detect=0
  '';

  # ddcutil
  hardware.i2c.enable = true;
}
