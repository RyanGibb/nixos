{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.reality;
  log = {
    loglevel = "warning";
    access = "none";
  };
  serverConfig = (pkgs.formats.json { }).generate "reality.json" {
    inherit log;
    inbounds = [
      {
        inherit (cfg) port;
        protocol = "vless";
        settings = {
          clients = [
            {
              id = "@uuid@";
              flow = "xtls-rprx-vision";
            }
          ];
          decryption = "none";
        };
        streamSettings = {
          network = "tcp";
          security = "reality";
          # unauthenticated connections are passed through to the real site
          realitySettings = {
            target = cfg.dest;
            serverNames = [ cfg.serverName ];
            privateKey = "@privatekey@";
            shortIds = [ cfg.shortId ];
          };
        };
      }
    ];
    outbounds = [ { protocol = "freedom"; } ];
  };
  matchServer = builtins.match "[[]?(.*[^]])[]]?:([0-9]+)";
  splitServer =
    server:
    let
      m = matchServer server;
    in
    {
      address = lib.elemAt m 0;
      port = lib.toInt (lib.elemAt m 1);
    };
  clientConfig =
    name: client:
    (pkgs.formats.json { }).generate "reality-${name}.json" {
      inherit log;
      inbounds = [
        {
          listen = "127.0.0.1";
          port = client.socksPort;
          protocol = "socks";
          settings.udp = true;
        }
        {
          listen = "127.0.0.1";
          port = client.httpPort;
          protocol = "http";
        }
      ];
      outbounds = [
        {
          protocol = "vless";
          settings = splitServer client.server // {
            id = "@uuid@";
            flow = "xtls-rprx-vision";
            encryption = "none";
          };
          streamSettings = {
            network = "tcp";
            security = "reality";
            realitySettings = {
              inherit (client) serverName publicKey shortId;
              fingerprint = "chrome";
            };
          }
          # tailscale's bypass mark, so the tunnel's own packets never route via an exit node
          // lib.optionalAttrs config.services.tailscale.enable { sockopt.mark = 524288; };
        }
      ];
    };
  hardening = {
    User = "reality";
    Group = "reality";
    Restart = "on-failure";
    RestartSec = "10s";
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateDevices = true;
  };
in
{
  options.custom.reality = {
    enable = lib.mkEnableOption "VLESS + XTLS-Vision + Reality server";
    dest = lib.mkOption {
      type = lib.types.str;
      example = "www.example.com:443";
      description = "TLS 1.3 site whose handshake is borrowed, and where unauthenticated connections are forwarded";
    };
    serverName = lib.mkOption {
      type = lib.types.str;
      default = lib.head (lib.splitString ":" cfg.dest);
      defaultText = lib.literalExpression "host part of dest";
      description = "SNI clients must send";
    };
    shortId = lib.mkOption {
      type = lib.types.str;
      description = "hex short id clients must send";
    };
    publicKey = lib.mkOption {
      type = lib.types.str;
      description = "x25519 public key matching secrets/reality-key.age, for clients";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = "TCP port to listen on";
    };

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
              serverName = lib.mkOption {
                type = lib.types.str;
                description = "SNI to send, the server's serverName";
              };
              publicKey = lib.mkOption { type = lib.types.str; };
              shortId = lib.mkOption { type = lib.types.str; };
              socksPort = lib.mkOption { type = lib.types.port; };
              httpPort = lib.mkOption {
                type = lib.types.port;
                default = config.socksPort + 1;
                defaultText = lib.literalExpression "socksPort + 1";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable || cfg.clients != { }) {
      users.users.reality = {
        isSystemUser = true;
        group = "reality";
      };
      users.groups.reality = { };

      age.secrets.reality-uuid = {
        file = ../secrets/reality-uuid.age;
        owner = "reality";
        group = "reality";
      };
    })

    (lib.mkIf cfg.enable {
      age.secrets.reality-key = {
        file = ../secrets/reality-key.age;
        owner = "reality";
        group = "reality";
      };

      systemd.services.reality = {
        description = "VLESS + Reality server";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = hardening // {
          RuntimeDirectory = "reality";
          RuntimeDirectoryMode = "0700";
          ExecStartPre = pkgs.writeShellScript "reality-config" ''
            install -m 600 ${serverConfig} /run/reality/config.json
            ${pkgs.replace-secret}/bin/replace-secret @uuid@ \
              ${config.age.secrets.reality-uuid.path} /run/reality/config.json
            ${pkgs.replace-secret}/bin/replace-secret @privatekey@ \
              ${config.age.secrets.reality-key.path} /run/reality/config.json
          '';
          ExecStart = "${lib.getExe pkgs.xray} run -c /run/reality/config.json";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];
    })

    {
      assertions = lib.mapAttrsToList (name: client: {
        assertion = matchServer client.server != null;
        message = "custom.reality.clients.${name}.server must be host:port";
      }) cfg.clients;

      systemd.services = lib.mapAttrs' (
        name: client:
        lib.nameValuePair "reality-client-${name}" {
          description = "VLESS + Reality client for ${name}";
          serviceConfig =
            hardening
            // {
              RuntimeDirectory = "reality-client-${name}";
              RuntimeDirectoryMode = "0700";
              ExecStartPre = pkgs.writeShellScript "reality-client-${name}-config" ''
                install -m 600 ${clientConfig name client} /run/reality-client-${name}/config.json
                ${pkgs.replace-secret}/bin/replace-secret @uuid@ \
                  ${config.age.secrets.reality-uuid.path} /run/reality-client-${name}/config.json
              '';
              ExecStart = "${lib.getExe pkgs.xray} run -c /run/reality-client-${name}/config.json";
            }
            // lib.optionalAttrs config.services.tailscale.enable {
              AmbientCapabilities = [ "CAP_NET_ADMIN" ];
              CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
            };
        }
      ) cfg.clients;
    }
  ];
}
