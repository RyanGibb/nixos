{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.hysteria;
  cert = config.security.acme-eon.certs.${cfg.domain};
  configTemplate = (pkgs.formats.yaml { }).generate "hysteria.yaml" {
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
  };

  config = lib.mkIf cfg.enable {
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
          install -m 600 ${configTemplate} /run/hysteria/config.yaml
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
  };
}
