{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/services/wireguard/default.nix
  ];

  machineColour = "white";

  services.tailscale.enable = true;

  services.logind.lidSwitch = "ignore";

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
  };
}
