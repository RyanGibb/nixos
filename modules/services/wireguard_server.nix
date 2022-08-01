{ pkgs, ... }:

{
  networking = {
    nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = [ "wg0" ];
    };
    firewall = {
      allowedUDPPorts = [ 51820 ];
      extraCommands = ''
        iptables -I FORWARD -i wg0 -o wg0 -j ACCEPT
      '';
      checkReversePath = false;
    };

    wireguard = {
      enable = true;
      interfaces.wg0 = {
        ips = [ "10.100.0.1/24" ];
        listenPort = 51820;

        # Route from wireguard to public internet, allowing server to act as VPN
        # postSetup = ''
        #   ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
        # '';

        # postShutdown = ''
        #   ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
        # '';

        privateKeyFile = "/etc/nixos/secret/wireguard_key";

        peers = [
          {
            # dell-xps
            publicKey = "+4FaBAbC8IeQz5LnA0fL2pfhhd2g5wKLse/vDTLpRxo=";
            allowedIPs = [ "10.100.0.2/32" ];
          }
          {
            # pixel-4a
            publicKey = "KPstJ3Dd8YgZ2vsu0RIzjxdZhv1RlAVw2PGqyV1+eX4=";
            allowedIPs = [ "10.100.0.3/32" ];
          }
        ];
      };
    };
  };
}
