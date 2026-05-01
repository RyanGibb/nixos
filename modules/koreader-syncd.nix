{
  config,
  lib,
  koreader-syncd,
  ...
}:

let
  cfg = config.custom.koreader-syncd;
  domain = config.networking.domain;
in
{
  options.custom.koreader-syncd = {
    enable = lib.mkEnableOption "koreader-syncd";
    port = lib.mkOption {
      type = lib.types.port;
      default = 7200;
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "kosync.${domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.koreader-syncd = {
      description = "KOReader sync server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${koreader-syncd.packages.${config.nixpkgs.hostPlatform.system}.default}/bin/koreader-syncd -a 0.0.0.0:${builtins.toString cfg.port} -d /var/lib/koreader-syncd/state.db";
        DynamicUser = true;
        StateDirectory = "koreader-syncd";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

    security.acme-eon.nginxCerts = [ cfg.domain ];
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${builtins.toString cfg.port}";
        };
      };
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "kosync";
        type = "CNAME";
        value = "owl";
      }
    ];
  };
}
