{ pkgs, config, lib, ... }:

let giteaSshPort = 3001; in
{
  security.acme = {
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    acceptTerms = true;
  };

  dns.enable = true;

  services.ryan-website.enable = true;
  services.ryan-website.cname = "vps";

  services.nginx.virtualHosts."${config.networking.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/index.html".root = pkgs.writeTextFile {
      name = "freumh";
      text = ''
<html>
<body>
<pre>
       ||
       \\
_      ||    __
 \    / \\  /  \
  \__/   \\/
          \\      __
    _    / \\    /  \_/
  _/ \  ||   \__/
      \//     \
      //       \
      ||        \_
</html>
</body>
</pre>
      '';
      destination = "/index.html";
    };
    locations."/404.html".extraConfig = ''
      return 200 "";
    '';
    extraConfig = ''
      error_page 404 /404.html;
    '';
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

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
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
    iptables -A OUTPUT -d ${config.hosting.serverIpv4} -t nat -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
    ip6tables -A OUTPUT -d ${config.hosting.serverIpv6} -t nat -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
  '';
}
