{ lib, ... }:

{
  imports = [
    ./common.nix
    ./matrix.nix
    ./twitcher.nix
    ./mailserver.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = {
    hostName = "vps";
    domain = "gibbr.org";
  };

  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;

  users.users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  users.users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";

  networking.firewall.allowedTCPPorts = lib.mkForce [ 25 80 443 465 993 ];
  networking.firewall.allowedUDPPorts = lib.mkForce [ 53 ];

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.nginx = {
    enable = true;
    virtualHosts."gibbr.org" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/gibbr.org";
    };
  };

  security.acme = {
    email = "ryan@gibbr.org";
    acceptTerms = true;
  };

  services.bind = {
    enable = true;
    zones."gibbr.org" = {
      master = true;
      file = "/etc/nixos/gibbr.org.zone";
      slaves = [
        "217.70.177.40" # ns6.gandi.net
        "127.0.0.1"
      ];
    };
  };

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

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
