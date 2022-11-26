{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
    ../../modules/personal/default.nix
    ../../modules/hosting/wireguard/default.nix
    #../../modules/dns/bind.nix
  ];

  custom.machineColour = "red";

  services.tailscale.enable = true;
  networking.networkmanager.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
