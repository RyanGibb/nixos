{ pkgs, lib, ... }:

let
  giteaSshPort = 3001;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
    ../../modules/personal/default.nix
    #../../modules/services/matrix.nix
    #../../modules/services/twitcher.nix
    #../../modules/services/mailserver.nix
    #../../modules/services/wireguard/default.nix
    #../../modules/services/gitea.nix
    #../../modules/services/mastodon.nix
    #../../modules/dns/bind.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  networking.hostName = "vps";

  custom.machineColour = "yellow";

  services.tailscale.enable = true;

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  # I ran into some issues building a MirageOS DNS unikernel on the server as it has a small amount (1GB) of ram.
  # This isn't an issue normally due to a healthy swapfile and low load, but opam seems to use the in-memory filesystem created by `pam-systemd` at `/run/user/$uid` which by default is limited to 10% of ram, with a number of inodes equal to this divided by 4096 (e.g. 4KB per inode).
  # The space wasn't an issue but the number of inodes were.
  # We explicitly set a large number of inodes to fix this.
  #services.logind.extraConfig = ''
  #  RuntimeDirectorySize=1G
  #  RuntimeDirectoryInodesMax=402566
  #'';

  #services.journald.extraConfig = ''
  #  SystemMaxUse=1G
  #'';

  #boot.kernel.sysctl = {
  #  "net.ipv4.ip_forward" = 1;
  #  "net.ipv6.conf.all.forwarding" = 1;
  #};
  
  #networking.firewall = {
  #  # keep tight control over open ports
  #  allowedTCPPorts = lib.mkForce [
  #    22  # SSH
  #    giteaSshPort
  #    25  # SMTP
  #    465 # SMTP TLS
  #    53  # DNS (over TCP)
  #    80  # HTTP
  #    443 # HTTPS
  #    993 # IMAP
  #  ];
  #  allowedUDPPorts = lib.mkForce [
  #    53    # DNS
  #    51820 # wireguard
  #  ];
  #  trustedInterfaces = [ "tailscale0" ];
  #};

  # proxy port 22 on ethernet interface to internal gitea ssh server
  # openssh server remains accessible on port 22 via vpn(s)
  #services.gitea.settings.server = {
  #  START_SSH_SERVER = true;
  #  SSH_LISTEN_PORT = giteaSshPort;
  #};
  #networking.firewall.extraCommands = ''
  #  iptables -A PREROUTING -t nat -i enp1s0 -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
  #  ip6tables -A PREROUTING -t nat -i enp1s0 -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}

  #  # proxy locally originating outgoing packets
  #  iptables -A OUTPUT -d ${config.custom.serverIpv4} -t nat -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
  #  ip6tables -A OUTPUT -d ${config.custom.serverIpv6} -t nat -p tcp --dport 22 -j REDIRECT --to-port ${builtins.toString giteaSshPort}
  #'';

  services.ryan-website.enable = true;
}
