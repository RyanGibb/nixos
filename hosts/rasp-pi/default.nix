{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/../secret/wifi.nix
    ../../modules/services/wireguard/default.nix
  ];

  machineColour = "red";

  networking.wireless.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
