{ config, pkgs, lib, ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../common/default.nix
    ../../secret/wifi.nix
    ../services/wireguard/default.nix
  ];

  networking.hostName = "rasp-pi";
  machineColour = "red";

  networking.wireless.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
