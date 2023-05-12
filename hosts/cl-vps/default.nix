{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "cl-vps";
  personal = {
    enable = true;
    tailscale = true;
    machineColour = "green";
  };

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];
}
