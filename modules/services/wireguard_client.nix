{
  networking = {
    firewall = {
        allowedUDPPorts = [ 51820 ];
        # https://wiki.archlinux.org/title/WireGuard#Loop_routing
        extraCommands = ''
          ip route add 192.168.1.214 via 10.100.0.1 dev wg0
        '';
    };

    wireguard = {
      enable = true;
      interfaces.wg0 = {
        ips = [ "10.100.0.2/24" ];
        listenPort = 51820;

        privateKeyFile = "/etc/nixos/secret/wireguard_key";

        peers = [
          {
            # vps
            publicKey = "Jg/zcR6fUiyZAONqB0csIwaN8BYHa5ccfwmKN5INmA8=";
            allowedIPs = [ "10.100.0.0/24" ];
            endpoint = "45.77.205.198:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
