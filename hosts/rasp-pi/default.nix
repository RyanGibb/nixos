{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    ./hardware-configuration.nix
    "${nixos-hardware}/raspberry-pi/4"
  ];

  networking.hostName = "rasp-pi";
  personal = {
    enable = true;
    tailscale = true;
    machineColour = "red";
  };

  networking.networkmanager.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
