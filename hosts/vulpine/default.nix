{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  personal = {
    enable = true;
    tailscale = true;
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

  swapDevices = [{
    device = "/swapfile";
    size = 8192;
  }];

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
