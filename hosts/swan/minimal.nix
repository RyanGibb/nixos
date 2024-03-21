{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    machineColour = "green";
  };

  services.openssh.openFirewall = true;

  swapDevices = [ { device = "/var/swap"; size = 1024; } ];
}
