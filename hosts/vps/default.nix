{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/services/matrix.nix
    ../../modules/services/twitcher.nix
    ../../modules/services/mailserver.nix
    ../../modules/services/wireguard/default.nix
    ../../modules/services/gitea.nix
    ../../modules/dns/bind.nix
  ];

  machineColour = "yellow";

  services.tailscale.enable = true;

  boot.loader.grub= {
    enable = true;
    device = "/dev/vda";
  };

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  # I ran into some issues building a MirageOS DNS unikernel on the server as it has a small amount (1GB) of ram.
  # This isn't an issue normally due to a healthy swapfile and low load, but opam seems to use the in-memory filesystem created by `pam-systemd` at `/run/user/$uid` which by default is limited to 10% of ram, with a number of inodes equal to this divided by 4096 (e.g. 4KB per inode).
  # The space wasn't an issue but the number of inodes were.
  # We explicitly set a large number of inodes to fix this.
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
    allowedTCPPorts = lib.mkForce [ 22 3001 25 53 80 443 465 993 ];
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

      iptables -A PREROUTING -t nat -i enp1s0 -p tcp --dport 22 -j REDIRECT --to-port 3001
    '';
  };

  services.gitea.settings.server = {
    START_SSH_SERVER = true;
    SSH_LISTEN_PORT = 3001;
  };

  services.openssh.listenAddresses = 
    # only listen on wireguard
    [ { addr = "10.0.0.1"; port = 22; } ];
  services."gibbr.org".enable = true;
}
