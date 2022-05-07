{ lib, ... }:

{
  imports = [
    ./common.nix
    ./matrix.nix
    ./twitcher.nix
    ./mailserver.nix
    ./secret.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = "vps";
    domain = "gibbr.org";
    useDHCP = false;
    interfaces.enp1s0.useDHCP = true;
    firewall = {
      allowedTCPPorts = lib.mkForce [ 25 53 80 443 465 993 ];
      allowedUDPPorts = lib.mkForce [ 53 ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  users = {
    users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
    users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  };

  services.nginx = {
    enable = true;
    virtualHosts."gibbr.org" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/gibbr.org";
      extraConfig = ''
        error_page 404 /404.html;
      '';
    };
  };

  security.acme = {
    email = "ryan@gibbr.org";
    acceptTerms = true;
  };

  services.bind = {
    enable = true;
    extraOptions = ''
      dnssec-enable yes;
      dnssec-validation yes;
      dnssec-lookaside auto;
    '';
    zones."gibbr.org" = {
      master = true;
      file = "/etc/nixos/dns/gibbr.org.zone.signed";
      # axfr zone transfer
      slaves = [
        "127.0.0.1"
      ];
    };
  };

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

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

  system.stateVersion = "21.11";
}
