{ pkgs, lib, ... }:

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
  };

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

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
  ];

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  programs.steam.enable = true;

  networking.extraHosts = "10.11.99.1 remarkable2";

  # sometimes I want to keep the cache for operating without internet
  nix.gc.automatic = lib.mkForce false;
}
