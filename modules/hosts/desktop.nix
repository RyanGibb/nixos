{ pkgs, ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../common/default.nix
    ../gui/sway.nix
    ../gui/i3.nix
    ../services/wireguard/default.nix
    <home-manager/nixos> 
  ];

  services.tailscale.enable = true;

  networking.hostName = "desktop";
  machineColour = "magenta";

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
  };
  
  swapDevices = [ { device = "/swapfile"; size = 8192; } ];

  boot.supportedFilesystems = [ "ntfs" ];

  services.avahi.enable = true;

  environment.systemPackages = with pkgs; [
    pciutils
    tor-browser-bundle-bin
    discord
    ffmpeg
    audio-recorder
  ];

  programs.steam.enable = true;
}
