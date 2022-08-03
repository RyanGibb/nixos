{ pkgs, lib, config, ... }:


let hosts = import ./hosts.nix; in
{
  networking = lib.mkIf (config.networking.hostName == "vps") {
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
      #   ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
      # '';

      # postShutdown = ''
      #   ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
      # '';

      # add clients
      peers = with lib.attrsets;
        mapAttrsToList (
          hostName: values: {
            allowedIPs = [ "${values.ip}/32" ];
            publicKey = values.publicKey;
          }
        ) hosts;
    };
  };
}
