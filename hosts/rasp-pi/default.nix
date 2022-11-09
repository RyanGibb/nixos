{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/services/wireguard/default.nix
    ../../modules/dns/bind.nix
  ];

  machineColour = "red";

  services.tailscale.enable = true;
  networking.networkmanager.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';

  services."gibbr.org".enable = true;
}
