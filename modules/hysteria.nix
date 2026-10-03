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
  clientSettings =
    client:
    {
      server = client.server;
      auth = "@password@";
    }
    // lib.optionalAttrs (client.sni != null) { tls.sni = client.sni; }
    # tailscale's bypass mark, so the tunnel's own packets never route via an exit node
    // lib.optionalAttrs config.services.tailscale.enable { quic.sockopts.fwmark = 524288; };
  clientConfig =
    name: client:
    (pkgs.formats.yaml { }).generate "hysteria-${name}.yaml" (
      clientSettings client
      // {
        socks5.listen = "127.0.0.1:${toString client.socksPort}";
        http.listen = "127.0.0.1:${toString client.httpPort}";
      }
    );
  tunConfig =
    name: client: (pkgs.formats.yaml { }).generate "hysteria-${name}-tun.yaml" (clientSettings client);
  tunSettings =
    name:
    pkgs.writeText "hysteria-${name}-tun.json" (
      builtins.toJSON {
        name = "hy-${name}";
        address = {
          ipv4 = "172.19.0.1/30";
          ipv6 = "fdfe:dcba:9876::1/126";
        };
        route = {
          ipv4 = [ "0.0.0.0/0" ];
          ipv6 = [ "::/0" ];
          ipv4Exclude = [
            "100.64.0.0/10"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "169.254.0.0/16"
          ];
          ipv6Exclude = [
            "fd7a:115c:a1e0::/48"
            "fe80::/10"
          ];
        };
      }
    );
  serverHost =
    server:
    let
      m = builtins.match "[[]([^]]*)[]](:.*)?|([^:]*)(:.*)?" server;
    in
    if lib.elemAt m 0 != null then lib.elemAt m 0 else lib.elemAt m 2;
  tunNames = lib.attrNames (lib.filterAttrs (_: client: client.tun) cfg.clients);
  clientService = unit: name: client: base: extra: {
    description = "hysteria2 client for ${name}";
    serviceConfig = {
      User = "hysteria";
      Group = "hysteria";
      RuntimeDirectory = unit;
      RuntimeDirectoryMode = "0700";
      ExecStartPre = pkgs.writeShellScript "${unit}-config" ''
        install -m 600 ${base} /run/${unit}/config.yaml
        if [ -r /etc/hysteria/${name}.yaml ]; then
          cat /etc/hysteria/${name}.yaml >> /run/${unit}/config.yaml
        else
          cat ${clientBandwidth name client} >> /run/${unit}/config.yaml
        fi
        ${extra}
        ${pkgs.replace-secret}/bin/replace-secret @password@ \
          ${config.age.secrets.hysteria.path} /run/${unit}/config.yaml
      '';
      ExecStart = "${lib.getExe pkgs.hysteria} client -c /run/${unit}/config.yaml";
      Restart = "on-failure";
      RestartSec = "10s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateDevices = true;
    }
    // lib.optionalAttrs config.services.tailscale.enable {
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
    };
  };
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
              tun = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "also generate hysteria-client-<name>-tun, routing the whole machine through this server; do not use at the same time as a tailscale exit node";
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
      assertions = lib.mapAttrsToList (name: client: {
        assertion = !client.tun || lib.stringLength name <= 12;
        message = "custom.hysteria.clients.${name}: tun interface hy-${name} exceeds 15 characters";
      }) cfg.clients;

      # the system stack hands the tun's connections back to the kernel
      networking.firewall.trustedInterfaces = map (n: "hy-${n}") tunNames;

      systemd.services = lib.concatMapAttrs (
        name: client:
        {
          "hysteria-client-${name}" =
            clientService "hysteria-client-${name}" name client (clientConfig name client)
              "";
        }
        // lib.optionalAttrs client.tun {
          "hysteria-client-${name}-tun" =
            lib.recursiveUpdate
              (clientService "hysteria-client-${name}-tun" name client (tunConfig name client) ''
                # the server is resolved once at start and excluded, else the tunnel would route into itself
                tun=$(${lib.getExe pkgs.getent} ahosts ${serverHost client.server} | cut -d' ' -f1 \
                  | ${lib.getExe pkgs.jq} -Rnc --slurpfile tun ${tunSettings name} '
                    [inputs | select(. != "")] | unique as $a
                    | if ($a | length) == 0 then error("cannot resolve ${serverHost client.server}") else $tun[0] end
                    | .route.ipv4Exclude += [$a[] | select(contains(":") | not)]
                    | .route.ipv6Exclude += [$a[] | select(contains(":"))]') || exit 1
                printf '\ntun: %s\n' "$tun" >> /run/hysteria-client-${name}-tun/config.yaml
              '')
              {
                description = "hysteria2 client for ${name}, routing all traffic";
                conflicts = map (n: "hysteria-client-${n}-tun.service") (lib.remove name tunNames);
                serviceConfig = {
                  AmbientCapabilities = [ "CAP_NET_ADMIN" ];
                  CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
                  PrivateDevices = false;
                  DeviceAllow = [ "/dev/net/tun rw" ];
                  # sing-tun leaves its policy rules behind when hysteria is killed
                  ExecStopPost =
                    "+"
                    + pkgs.writeShellScript "hysteria-client-${name}-tun-cleanup" ''
                      for p in $(seq 9000 9010); do
                        while ${pkgs.iproute2}/bin/ip rule del priority $p 2>/dev/null; do :; done
                        while ${pkgs.iproute2}/bin/ip -6 rule del priority $p 2>/dev/null; do :; done
                      done
                    '';
                };
              };
        }
      ) cfg.clients;
    }
  ];
}
