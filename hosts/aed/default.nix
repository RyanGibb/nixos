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

  boot.supportedFilesystems = [ "ntfs" "zfs" ];

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # https://gitlab.freedesktop.org/wlroots/wlroots/-/issues/3706#note_2043550
  boot.kernelPatches = [ {
    name = "sway-hotplug";
    patch = ./sway-hotplug-kernel.patch;
  } ];

  environment.systemPackages = with pkgs; [
    cctk
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
  ];

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

  services.kmonad = {
    # enable = true;
    keyboards.internal = {
      # todo find by-id
      device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
      config = builtins.readFile ./kmonad.kbd;
    };
  };

  services = {
    syncthing = {
      enable = true;
      user = config.custom.username;
      dataDir = "/home/ryan/syncthing";
      configDir = "/home/ryan/.config/syncthing";
    };
  };

  networking.hostId = "e768032f";
}
