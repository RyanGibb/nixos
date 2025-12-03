{
  pkgs,
  config,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  custom = {
    enable = true;
    tailscale = true;
    homeManager.enable = true;
  };

  networking.networkmanager.enable = true;
  services.openssh.openFirewall = true;

  home-manager.users.${config.custom.username}.config.custom.machineColour = "red";

  system.stateVersion = "24.05";
}
