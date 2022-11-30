{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
    ../../modules/personal/default.nix
    ../../modules/personal/gui/sway.nix
    ../../modules/personal/gui/i3.nix
    ../../modules/personal/gui/extra.nix
    ../../modules/hosting/wireguard/default.nix
  ];

  services.tailscale.enable = true;

  networking.hostName = "desktop";
  personal = {
    enable = true;
    machineColour = "magenta";
    laptop = true;
    gui.i3 = true;
    gui.sway = true;
    gui.extra = true;
  };

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

  specialisation.nvidia.configuration = {
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
