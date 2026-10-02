{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.hysteria;
  cert = config.security.acme-eon.certs.${cfg.domain};
  serverConfig = (pkgs.formats.yaml { }).generate "hysteria.yaml" {
    listen = ":${toString cfg.port}";
    tls = {
      cert = "${cert.directory}/fullchain.pem";
      key = "${cert.directory}/key.pem";
    };
    auth = {
      type = "password";
      password = "@password@";
    };
    # unauthenticated probes are transparently served the real site instead
    masquerade = {
      type = "proxy";
      proxy = {
        url = cfg.masqueradeUrl;
        rewriteHost = true;
      };
    };
  };
  clientConfig =
    name: client:
    (pkgs.formats.yaml { }).generate "hysteria-${name}.yaml" (
      {
        server = client.server;
        auth = "@password@";
        socks5.listen = "127.0.0.1:${toString client.socksPort}";
        http.listen = "127.0.0.1:${toString client.httpPort}";
      }
      // lib.optionalAttrs (client.sni != null) { tls.sni = client.sni; }
    );
  clientBandwidth =
    name: client:
    (pkgs.formats.yaml { }).generate "hysteria-${name}-bandwidth.yaml" {
      bandwidth = {
        inherit (client) up down;
      };
    };
in
{
  options.custom.hysteria = {
    enable = lib.mkEnableOption "hysteria2 server";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "acme-eon cert to serve, and the name clients dial";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = "UDP port to listen on";
    };
    masqueradeUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://${cfg.domain}/";
      defaultText = lib.literalExpression ''"https://''${config.custom.hysteria.domain}/"'';
      description = "site shown to anything that fails authentication";
    };
    natpmp = lib.mkEnableOption "ask the router to forward the port over NAT-PMP";

    clients = lib.mkOption {
      default = { };
      description = "client profiles, started on demand rather than at boot";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            options = {
              server = lib.mkOption {
                type = lib.types.str;
                description = "host:port to dial";
              };
              sni = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "TLS server name when it differs from the host dialled, e.g. when dialling by IP";
              };
              socksPort = lib.mkOption { type = lib.types.port; };
              httpPort = lib.mkOption {
                type = lib.types.port;
                default = config.socksPort + 1;
                defaultText = lib.literalExpression "socksPort + 1";
              };
              # brutal sends at the declared rate regardless of loss, so
              # overstating these is both antisocial and conspicuous
              up = lib.mkOption {
                type = lib.types.str;
                default = "20 mbps";
                description = "upload rate; /etc/hysteria/<name>.yaml overrides the bandwidth block if present";
              };
              down = lib.mkOption {
                type = lib.types.str;
                default = "50 mbps";
                description = "download rate; /etc/hysteria/<name>.yaml overrides the bandwidth block if present";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable || cfg.clients != { }) {
      users.users.hysteria = {
        isSystemUser = true;
        group = "hysteria";
      };
      users.groups.hysteria = { };

      age.secrets.hysteria = {
        file = ../secrets/hysteria.age;
        owner = "hysteria";
        group = "hysteria";
      };
    })

    (lib.mkIf cfg.enable {
      security.acme-eon.certs.${cfg.domain}.reloadServices = [ "hysteria" ];

      systemd.services.hysteria = {
        description = "hysteria2 server";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "acme-eon-${cfg.domain}.service"
        ];
        serviceConfig = {
          User = "hysteria";
          Group = "hysteria";
          SupplementaryGroups = [ cert.group ];
          RuntimeDirectory = "hysteria";
          RuntimeDirectoryMode = "0700";
          ExecStartPre = pkgs.writeShellScript "hysteria-config" ''
            install -m 600 ${serverConfig} /run/hysteria/config.yaml
            ${pkgs.replace-secret}/bin/replace-secret @password@ \
              ${config.age.secrets.hysteria.path} /run/hysteria/config.yaml
          '';
          ExecStart = "${lib.getExe pkgs.hysteria} server -c /run/hysteria/config.yaml";
          Restart = "on-failure";
          RestartSec = "10s";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateDevices = true;
        };
      };

      # mappings are leased, so re-request rather than mapping once at boot
      systemd.services.hysteria-natpmp = lib.mkIf cfg.natpmp {
        description = "NAT-PMP port mapping for hysteria2";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.libnatpmp} -a ${toString cfg.port} ${toString cfg.port} udp 3600";
        };
      };
      systemd.timers.hysteria-natpmp = lib.mkIf cfg.natpmp {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1m";
          OnUnitActiveSec = "30m";
        };
      };

      networking.firewall.allowedUDPPorts = [ cfg.port ];
    })

    {
      systemd.services = lib.mapAttrs' (
        name: client:
        lib.nameValuePair "hysteria-client-${name}" {
          description = "hysteria2 client for ${name}";
          serviceConfig = {
            User = "hysteria";
            Group = "hysteria";
            RuntimeDirectory = "hysteria-client-${name}";
            RuntimeDirectoryMode = "0700";
            ExecStartPre = pkgs.writeShellScript "hysteria-client-${name}-config" ''
              install -m 600 ${clientConfig name client} /run/hysteria-client-${name}/config.yaml
              if [ -r /etc/hysteria/${name}.yaml ]; then
                cat /etc/hysteria/${name}.yaml >> /run/hysteria-client-${name}/config.yaml
              else
                cat ${clientBandwidth name client} >> /run/hysteria-client-${name}/config.yaml
              fi
              ${pkgs.replace-secret}/bin/replace-secret @password@ \
                ${config.age.secrets.hysteria.path} /run/hysteria-client-${name}/config.yaml
            '';
            ExecStart = "${lib.getExe pkgs.hysteria} client -c /run/hysteria-client-${name}/config.yaml";
            Restart = "on-failure";
            RestartSec = "10s";
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateDevices = true;
          };
        }
      ) cfg.clients;
    }
  ];
}
