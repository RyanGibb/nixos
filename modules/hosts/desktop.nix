{ pkgs, ... }:

{
  imports = [
    ../common/default.nix
    ../gui/sway.nix
    ../gui/i3.nix
    <home-manager/nixos> 
  ];

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
  };

  networking = {
    hostName = "desktop";
    useDHCP = false;
  };

  users = {
    users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
    users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  };

  # Needed for Keychron K2
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
  boot.kernelModules = [ "hid-apple" ];

  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/media/hdd" = { 
    device = "/dev/disk/by-label/HDD";
    options = [ "nofail" "x-systemd.device-timeout=1ms" "x-systemd.automount" "x-systemd.idle-timeout=10min" ];
  };

  swapDevices = [ { device = "/swapfile"; size = 8192; } ];

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

  machineColour = "magenta";

  programs.steam.enable = true;
}
