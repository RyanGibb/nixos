{ lib, ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../common/default.nix
    ../services/matrix.nix
    ../services/twitcher.nix
    ../services/mailserver.nix
    ../services/wireguard/default.nix
    ../../secret/default.nix
    ../dns/bind.nix
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
      allowedUDPPorts = lib.mkForce [ 53 51820 ];
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

  networking.firewall.extraCommands = ''
    iptables -P FORWARD DROP

    ### proxy HTTP/HTTPS

    #### forward syn packet
    # iptables -A FORWARD -i enp1s0 -o tailscale0 -p tcp --syn --match multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT

    #### forward packets for established flows bidirectionally
    # iptables -A FORWARD -i enp1s0 -o tailscale0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    # iptables -A FORWARD -i tailscale0 -o enp1s0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    #### proxy ports
    # iptables -t nat -A PREROUTING -i enp1s0 -p tcp --match multiport --dports 80,443 -j DNAT --to-destination 100.92.63.87
    # iptables -t nat -A POSTROUTING -o tailscale0 -p tcp --match multiport --dports 80,443 -d 100.92.63.87 -j SNAT --to-source 100.125.253.71

    ### proxy DNS
    # iptables -A FORWARD -i enp1s0 -o tailscale0 -p udp -j ACCEPT
    # iptables -A FORWARD -i tailscale0 -o enp1s0 -p udp -j ACCEPT
    # iptables -t nat -A PREROUTING -i enp1s0 -p udp --dport 53 -j DNAT --to-destination 100.92.63.87
    # iptables -t nat -A POSTROUTING -o tailscale0 -p udp --dport 53 -d 100.92.63.87 -j SNAT --to-source 100.125.253.71
  '';

  security.acme = {
    defaults.email = "ryan@gibbr.org";
    acceptTerms = true;
    certs."gibbr.org".extraDomainNames = [ "www.gibbr.org" ];
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

  wireguard.server = true;

  machineColour = "yellow";
}
