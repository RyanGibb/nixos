{ pkgs, lib, config, ... }:

with lib;

let cfg = config.services.wireguard; in
{
  imports = [
    ./server.nix
  ];

  options.services.wireguard = {
    enable = mkOption {
      type = with types; bool;
      default = true;
    };
    server = mkOption {
      type = with types; bool;
      default = config.services.wireguard.hosts.${config.networking.hostName}.server;
    };
    hosts =
      let hostOps = { ... }: {
        options = {
          ip = mkOption {
            type = types.str;
          };
          publicKey = mkOption {
            type = types.str;
          };
          server = mkOption {
            type = types.bool;
            default = false;
          };
        };
      };
      in mkOption {
        type = with types; attrsOf (submodule hostOps);
      };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ wireguard-tools ];
    networking = {
      # populate /etc/hosts with hostnames and IPs
      extraHosts = builtins.concatStringsSep "\n" (
        attrsets.mapAttrsToList (
          hostName: values: "${values.ip} ${hostName}"
        ) cfg.hosts
      );

      firewall = {
        allowedUDPPorts = [ 51820 ];
        checkReversePath = false;
      };

      wireguard = {
        enable = true;
        interfaces.wg0 = {
          ips = [ "${cfg.hosts.${config.networking.hostName}.ip}/24" ];
          listenPort = 51820;
          privateKeyFile = "${config.secretsDir}/wireguard-key-${config.networking.hostName}";
          peers = mkIf (!cfg.server) [
            {
              allowedIPs = [ "10.0.0.0/24" ];
              publicKey = "${cfg.hosts.vps.publicKey}";
              endpoint = "${config.hosting.serverIpv4}:51820";
              persistentKeepalive = mkIf (config.networking.hostName == "rasp-pi") 25;
            }
          ];
        };
      };
    };
  };
}
