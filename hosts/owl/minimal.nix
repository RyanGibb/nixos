{ pkgs, config, lib, eilean, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour =
    "yellow";

  boot.tmp.cleanOnBoot = true;

  swapDevices = [{
    device = "/var/swap";
    size = 4096;
  }];
}
