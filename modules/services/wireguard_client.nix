{ lib, config, ... }:

{
  imports = [
    ../common/vpn_addresses.nix
  ];

  networking = {
    firewall = {
        allowedUDPPorts = [ 51820 ];
        checkReversePath = false;
    };

    wireguard = {
      enable = true;
      interfaces.wg0 =
        let vpnAddress = config.vpnAddresses.${config.networking.hostName}; in {
        ips = [ "${vpnAddress}/24" ];
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
