{ pkgs, lib, config, ... }:


let cfg = config.services.wireguard; in
{
  config.networking = lib.mkIf cfg.server {
    nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = [ "wg0" ];
    };
    firewall = {
      extraCommands = ''
        iptables -I FORWARD -i wg0 -o wg0 -j ACCEPT
      '';
      trustedInterfaces = [ "wg0" ];
    };

    wireguard.interfaces.wg0 = {
      # Route from wireguard to public internet, allowing server to act as VPN
      # postSetup = ''
      #   ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      # '';

      # postShutdown = ''
      #   ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      # '';

      peers = [
        {
          allowedIPs = [ "${cfg.addresses.dell-xps}/32" ];
          publicKey = "+4FaBAbC8IeQz5LnA0fL2pfhhd2g5wKLse/vDTLpRxo=";
        }
        {
          allowedIPs = [ "${cfg.addresses.pixel-4a}/32" ];
          publicKey = "KPstJ3Dd8YgZ2vsu0RIzjxdZhv1RlAVw2PGqyV1+eX4=";
        }
      ];
    };
  };
}
