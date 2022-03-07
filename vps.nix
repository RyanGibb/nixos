{
  imports = [
    ./common.nix
    ./matrix.nix
    ./twitcher.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  networking = {
    hostName = "vps";
    domain = "gibbr.org";
  };

  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;

  users.users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  users.users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";

  networking.firewall.allowedTCPPorts = [ 53 80 443 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

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
    };
  };

  services.journald.extraConfig = ''
    SystemMaxUse=2G
  '';

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  system.stateVersion = "21.11";
}

