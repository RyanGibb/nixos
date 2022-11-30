{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "rasp-pi";
  personal = {
    enable = true;
    machineColour = "red";
  };

  services.tailscale.enable = true;
  networking.networkmanager.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
