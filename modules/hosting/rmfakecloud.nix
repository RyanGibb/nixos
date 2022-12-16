{ pkgs, config, lib, ... }:

with lib;

let cfg = config.hosting.rmfakecloud; in
{
  options.hosting.rmfakecloud = {
    enable = mkEnableOption "rmfakecloud";
    port = mkOption {
      type = types.port;
      default = 8082;
    };
    domain = mkOption {
      type = types.str;
      default = "rmfakecloud.${config.networking.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    services.rmfakecloud = {
      enable = true;
      storageUrl = "https://${cfg.domain}";
      port = cfg.port;
      environmentFile = "${config.custom.secretsDir}/rmfakecloud.env";
      extraSettings = {
        RM_SMTP_SERVER = "mail.freumh.org:465";
        RM_SMTP_USERNAME = "remarkable";
      };
    };

    mailserver.loginAccounts."misc@${config.networking.domain}".aliases = [ "remarkable" ];

    # nginx handles letsencrypt
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = ''
          http://localhost:${builtins.toString cfg.port}
        '';
      };
    };

    dns.records = [
      {
        name = "rmfakecloud";
        type = "CNAME";
        data = "vps";
      }
    ];
  };
}
