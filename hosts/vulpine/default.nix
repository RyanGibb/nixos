{ pkgs, config, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    printing = true;
    gui.kde = true;
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
      gui.sway.idle = "suspend_long";
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

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/481c5422-0311-4d51-a5d9-b7d7ac1d5fac";
    fsType = "ext4";
  };

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
  jellyfin-media-player
  mangohud
  ];

  security.sudo.extraConfig = ''
    Defaults !tty_tickets
  '';

  services.avahi.enable = true;

  specialisation.nvidia.configuration = {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = false;
  };

  networking.firewall.allowedTCPPorts = [ 1234 ];
  networking.firewall.allowedUDPPorts = [ 1234 ];

  # allow wake from USB
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
  '';

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession = {
      enable = true;
      env.MANGOHUD = "1";
    };
    dedicatedServer.openFirewall = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;  # reduces stutter
    env.MANGOHUD = "1";
  };

  programs.gamemode.enable = true;
}
