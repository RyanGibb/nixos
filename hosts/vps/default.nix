{ pkgs, lib, config, ... }:

let giteaSshPort = 3001; in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
    ../../modules/personal/default.nix
    ../../modules/dns/bind.nix
    ../../modules/services/bind.nix
    #../../modules/services/matrix.nix
    #../../modules/services/twitcher.nix
    #../../modules/services/mailserver.nix
    ../../modules/services/wireguard/default.nix
    #../../modules/services/gitea.nix
    #../../modules/services/mastodon.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking.hostName = "vps";

  custom.machineColour = "yellow";

  services.tailscale.enable = true;

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  
  networking.firewall = {
    # keep tight control over open ports
    allowedTCPPorts = lib.mkForce [
      22  # SSH
      giteaSshPort
      25  # SMTP
      465 # SMTP TLS
      53  # DNS (over TCP)
      80  # HTTP
      443 # HTTPS
      993 # IMAP
    ];
    allowedUDPPorts = lib.mkForce [
      53    # DNS
      51820 # wireguard
    ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # proxy port 22 on ethernet interface to internal gitea ssh server
  # openssh server remains accessible on port 22 via vpn(s)
  services.gitea.settings.server = {
    START_SSH_SERVER = true;
    SSH_LISTEN_PORT = giteaSshPort;
  };
  networking.firewall.extraCommands = ''
    iptables -A PREROUTING -t nat -i enp1s0 -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
    ip6tables -A PREROUTING -t nat -i enp1s0 -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}

    # proxy locally originating outgoing packets
    iptables -A OUTPUT -d ${config.custom.serverIpv4} -t nat -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
    ip6tables -A OUTPUT -d ${config.custom.serverIpv6} -t nat -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
  '';

  services.ryan-website.enable = true;
}
