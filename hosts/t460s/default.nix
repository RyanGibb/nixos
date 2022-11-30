{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    machineColour = "white";
  };

  services.tailscale.enable = true;

  services.logind.lidSwitch = "ignore";

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
  };
}
