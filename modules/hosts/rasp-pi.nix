{ config, pkgs, lib, ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../common/default.nix
    ../../secret/wifi.nix
    ../services/wireguard/default.nix
  ];

  boot.loader.grub.enable = lib.mkForce false;

  networking.wireless.enable = true;
  
  users = {
    users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
    users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  };

  networking = {
    hostName = "rasp-pi";
    domain = "gibbr.org";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';

  nix.autoOptimiseStore = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  machineColour = "red";
}
