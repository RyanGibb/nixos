{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "vps";
  personal = {
    enable = true;
    tailscale = true;
    machineColour = "yellow";
  };

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];
}
