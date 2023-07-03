{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "yellow";
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];
}
