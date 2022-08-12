{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/services/matrix.nix
    ../../modules/services/twitcher.nix
    ../../modules/services/mailserver.nix
    ../../modules/services/wireguard/default.nix
    ../../modules/../secret/default.nix
    ../../modules/dns/bind.nix
  ];

  machineColour = "yellow";

  services.tailscale.enable = true;

  boot.loader.grub= {
    enable = true;
    device = "/dev/vda";
  };

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  services.logind.extraConfig = ''
    RuntimeDirectorySize=1G
    RuntimeDirectoryInodesMax=402566
  '';

  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  
  networking.firewall = {
    allowedTCPPorts = lib.mkForce [ 25 53 80 443 465 993 ];
    allowedUDPPorts = lib.mkForce [ 53 51820 ];
    trustedInterfaces = [ "tailscale0" ];
    extraCommands = ''
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
  };

  services.nginx = {
    enable = true;
    virtualHosts."gibbr.org" = {
      forceSSL = true;
      enableACME = true;
      # TODO make gibbr.org nix derivation
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
    virtualHosts."_.gibbr.org" = {
      extraConfig = ''
        return 404;
      '';
    };
  };

  security.acme = {
    defaults.email = "ryan@gibbr.org";
    acceptTerms = true;
    certs."gibbr.org".extraDomainNames = [ "www.gibbr.org" ];
  };
}
