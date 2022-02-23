# man 5 configuration.nix

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./common.nix
    ./packages.nix
    ./programs.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "vps";

  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;

  users.users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  users.users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";

  networking.firewall.allowedTCPPorts = [ 53 80 443 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.nginx = {
    enable = true;
    virtualHosts."gibbr.org" = {
      addSSL = true;
      enableACME = true;
      root = "/var/www/gibbr.org";
    };
  };
  #systemd.services.nginx.serviceConfig.ProtectHome = lib.mkForce false;
  #systemd.services.nginx.serviceConfig.ProtectSystem = lib.mkForce false;
  #systemd.services.nginx.serviceConfig.ReadOnlyPaths = [ "/home/" ];

  security.acme = {
    email = "ryan@gibb.xyz";
    acceptTerms = true;
    #certs = {
    #  "gibbr.org".email = "ryan@gibbr.org";
    #};
  };

  services.bind = {
    enable = true;
    zones."gibbr.org" = {
      master = true;
      file = "/var/dns/gibbr.org";
    };
  };

  system.stateVersion = "21.11";
}

