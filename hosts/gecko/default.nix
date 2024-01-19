{ pkgs, lib, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "blue";
    laptop = true;
    printing = true;
    gui.i3 = true;
    gui.sway = true;
    gui.extra = true;
    ocaml = true;
    backup.enable = true;
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
    (python3.withPackages (p: with p; [
      numpy
      matplotlib
      pandas
    ]))
    python39Packages.pip
    jupyter
    #vagrant
    discord
    #teams
    wine64
    anki
    lsof
    wally-cli
    gthumb
  ];

  virtualisation.docker.enable = true;
  users.users.ryan.extraGroups = [ "docker" ];

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
}
