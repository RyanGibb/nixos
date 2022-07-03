{ config, pkgs, lib, ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../common/default.nix
    ../../secret/wifi.nix
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
    firewall = {
      allowedTCPPorts = lib.mkForce [ 25 53 80 443 465 993 ];
      allowedUDPPorts = lib.mkForce [ 53 ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."gibbr.org" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/gibbr.org";
      extraConfig = ''
        error_page 403 =404 /404.html;
        error_page 404 /404.html;
      '';
    };
    virtualHosts."www.gibbr.org" = {
      addSSL = true;
      useACMEHost = "gibbr.org";
      extraConfig = ''
        return 301 $scheme://gibbr.org$request_uri;
      '';
    };
  };

  security.acme = {
    defaults.email = "ryan@gibbr.org";
    acceptTerms = true;
    certs."gibbr.org".extraDomainNames = [ "www.gibbr.org" ];
  };

  services.logind.extraConfig = ''
    RuntimeDirectorySize=1G
    RuntimeDirectoryInodesMax=402566
  '';

  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  nix.autoOptimiseStore = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  machineColour = "red";
}
