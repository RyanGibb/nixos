{ pkgs, lib, config, ... }:

let cfg = config.services.wireguard; in
let hosts = import ./hosts.nix; in
{
  imports = [
    ./server.nix
  ];

  options.services.wireguard = {
    enable = lib.mkOption {
      type = with pkgs.lib.types; bool;
      default = true;
    };
    server = lib.mkOption {
      type = with pkgs.lib.types; bool;
      default = config.networking.hostName == "vps";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [ wireguard-tools ];
    networking = lib.mkIf cfg.enable {
      # populate /etc/hosts with hostnames and IPs
      extraHosts = builtins.concatStringsSep "\n" (
        lib.attrsets.mapAttrsToList (
          hostName: values: "${values.ip} ${hostName}"
        ) hosts
      );

      firewall = {
        allowedUDPPorts = [ 51820 ];
        checkReversePath = false;
      };

      wireguard = {
        enable = true;
        interfaces.wg0 = {
          ips = [ "${hosts.${config.networking.hostName}.ip}/24" ];
          listenPort = 51820;
          privateKeyFile = "/etc/nixos/secrets/wireguard_key_${config.networking.hostName}";
          peers = lib.mkIf (!cfg.server) [
            {
              allowedIPs = [ "10.0.0.0/24" ];
              publicKey = "${hosts.vps.publicKey}";
              endpoint = "78.141.192.229:51820";
              persistentKeepalive = lib.mkIf (config.networking.hostName == "rasp-pi") 25;
            }
          ];
        };
      };
    };
  };
}
