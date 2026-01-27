{
  config,
  lib,
  ...
}:

let
  cfg = config.custom.rmfakecloud;
  domain = config.networking.domain;
in
{
  options.custom.rmfakecloud = {
    enable = lib.mkEnableOption "rmfakecloud";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8082;
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "rmfakecloud.${domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.rmfakecloud.file = ../secrets/rmfakecloud.age;
    services.rmfakecloud = {
      enable = true;
      storageUrl = "https://${cfg.domain}";
      port = cfg.port;
      environmentFile = config.age.secrets.rmfakecloud.path;
      extraSettings = {
        RM_SMTP_SERVER = "mail.freumh.org:465";
        RM_SMTP_USERNAME = "misc@${domain}";
        RM_SMTP_FROM = "remarkable@${domain}";
      };
    };

    mailserver.loginAccounts."misc@${domain}".aliases = [ "remarkable@${domain}" ];

    security.acme-eon.nginxCerts = [ cfg.domain ];
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      # to allow syncing
      # another option would just be opening a separate port for this
      clientMaxBodySize = "100M";
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        locations."/".proxyPass = ''
          http://localhost:${builtins.toString cfg.port}
        '';
      };
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "rmfakecloud";
        type = "CNAME";
        value = "vps";
      }
    ];
  };
}
