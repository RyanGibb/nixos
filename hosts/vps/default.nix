{ pkgs, config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "vps";
  personal = {
    enable = true;
    tailscale = true;
    machineColour = "yellow";
  };

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  eilean = {
    publicInterface = "enp1s0";

    mailserver.enable = true;
    matrix.enable = true;
    turn.enable = true;
    mastodon.enable = true;
    gitea.enable = true;
    dns.enable = true;
  };

  hosting = {
    freumh.enable = true;
    nix-cache.enable = true;
    rmfakecloud.enable = true;
  };

  dns = {
    soa.serial = lib.mkForce 2018011624;
    records = [
      {
        name = "@";
        type = "TXT";
        data = "google-site-verification=rEvwSqf7RYKRQltY412qMtTuoxPp64O3L7jMotj9Jnc";
      }
      {
        name = "teapot";
        type = "CNAME";
        data = "vps";
      }
    ];
  };

  services.nginx.virtualHosts."teapot.${config.networking.domain}" = {
    extraConfig = ''
      return 418;
    '';
  };

  services = {
    ryan-website = {
      enable = true;
      cname = "vps";
    };
    twitcher = {
      enable = true;
      cname = "vps";
      dotenvFile = "${config.custom.secretsDir}/twitcher.env";
    };
    eeww = {
      #enable = true;
      domain = config.services.ryan-website.domain;
    };
  };

  networking.firewall =
    let
      turn-range = with config.services.coturn; {
        from = min-port;
        to = max-port;
      };
    in {
      # keep tight control over open ports
      allowedTCPPorts = lib.mkForce [
        22   # SSH
        config.eilean.gitea.sshPort
        25   # SMTP
        465  # SMTP TLS
        53   # DNS (over TCP)
        80   # HTTP
        443  # HTTPS
        993  # IMAP
        3478 # STUN
      ];
      allowedTCPPortRanges = [ turn-range ];
      allowedUDPPorts = lib.mkForce [
        53    # DNS
        51820 # wireguard
        3478  # STUN
      ];
      allowedUDPPortRanges = [ turn-range ];
      trustedInterfaces = [ "tailscale0" ];
  };

  # boot.kernel.sysctl = {
  #   "net.ipv4.ip_forward" = 1;
  #   "net.ipv6.conf.all.forwarding" = 1;
  # };
}
