{ pkgs, config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    laptop = true;
    gui.i3 = true;
    gui.sway = true;
    workstation = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour =
    "magenta";

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  services.avahi.enable = true;

  environment.systemPackages = with pkgs; [ pciutils ];

  programs.steam.enable = true;

  specialisation.nvidia.configuration = {
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
