{ pkgs, config, ... }:

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
    custom = {
      machineColour = "magenta";
      calendar.enable = true;
      battery.enable = true;
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
                                     steam-launcher
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
}
