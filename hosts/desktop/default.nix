{ pkgs, ... }:

{
  imports = [
    ../hardware-configuration.nix
    ../modules/common/default.nix
    ../modules/gui/sway.nix
    ../modules/gui/i3.nix
    ../modules/services/wireguard/default.nix
  ];

  services.tailscale.enable = true;

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
