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

  services.nginx = {
    enable = true;
    virtualHosts."gibbr.org" = {
      #forceSSL = true;
      #enableACME = true;
      root = "/var/www/gibbr.org";
      extraConfig = ''
        error_page 403 =404 /404.html;
        error_page 404 /404.html;
      '';
    };
    virtualHosts."www.gibbr.org" = {
      #addSSL = true;
      #useACMEHost = "gibbr.org";
      extraConfig = ''
        return 301 $scheme://gibbr.org$request_uri;
      '';
    };
  };

  #security.acme = {
  #  defaults.email = "ryan@gibbr.org";
  #  acceptTerms = true;
  #  certs."gibbr.org".extraDomainNames = [ "www.gibbr.org" ];
  #};

  networking.networkmanager.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
