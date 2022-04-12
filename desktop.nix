{ pkgs, ... }:

{
  imports = [
    ./common.nix
    ./gui.nix
    ./kde.nix
    <home-manager/nixos> 
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
    };
    grub = {
      enable = true;
      default = "saved";
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
  };

  networking.hostName = "desktop";

  networking.useDHCP = false;
  networking.interfaces.wlp4s0.useDHCP = true;

  users.users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  users.users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";

  # Needed for Keychron K2
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
  boot.kernelModules = [ "hid-apple" ];

  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/mnt/hdd".device = "/dev/disk/by-label/HDD";

  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns = true;
  };

  environment.systemPackages = with pkgs; [
    pciutils
    tor-browser-bundle-bin
    discord
    ffmpeg
    audio-recorder
  ];

  programs.steam.enable = true;

  system.stateVersion = "21.11";
}
