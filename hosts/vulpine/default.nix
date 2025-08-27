{ pkgs, config, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    laptop = true;
    printing = true;
    gui.i3 = true;
    gui.sway = true;
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
        zeroconf_port = 1234;
      };
    };
    services.gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-tty;
    custom = {
      machineColour = "magenta";
      calendar.enable = true;
      battery.enable = true;
      gui.sway.idle = "suspend";
    };
    home.sessionVariables = {
      LEDGER_FILE = "~/vault/finances.ledger";
    };
  };

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  environment.systemPackages = with pkgs; [
    pciutils
    file-roller
    unzip
    cheese
    chromium
    calibre
    zotero
    element-desktop
    spotify
    gimp
    gthumb
    restic
    evince
    libreoffice
    obs-studio
    ffmpeg
    deploy-rs
    nix-prefetch-git
    tcpdump
    pandoc
    ledger
    nixd
    (pkgs.kodi-wayland.withPackages (kodiPkgs: with kodiPkgs; [
      jellyfin
    ]))
  ];

  security.sudo.extraConfig = ''
    Defaults !tty_tickets
  '';

  services.avahi.enable = true;

  programs.steam.enable = true;

  specialisation.nvidia.configuration = {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = false;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
  '';

  networking.firewall.allowedTCPPorts = [ 1234 ];
  networking.firewall.allowedUDPPorts = [ 1234 ];
}
