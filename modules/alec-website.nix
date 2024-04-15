{ pkgs, config, lib, alec-website, ... }:

with lib;

let cfg = config.custom.website.alec;
in {
  options = {
    custom.website.alec = {
      enable = mkEnableOption "Alec's website";
      zone = mkOption {
        type = types.str;
        default = "${config.networking.domain}";
      };
      domain = mkOption {
        type = types.str;
        default = "alec.${config.networking.domain}";
      };
      cname = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          CNAME to create DNS records for.
          Ignored if null
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.domain}" = {
          forceSSL = true;
          enableACME = true;
          root =
            "${alec-website.packages.${pkgs.stdenv.hostPlatform.system}.default}";
          locations."/var/".extraConfig = ''
            alias /var/${cfg.domain}/;
          '';
          extraConfig = ''
            error_page 403 =404 /404.html;
            error_page 404 /404.html;
            # see http://nginx.org/en/docs/http/ngx_http_log_module.html#access_log
            access_log /var/log/nginx/${cfg.domain}.log;
          '';
        };
        "www.${cfg.domain}" = {
          forceSSL = true;
          useACMEHost = cfg.domain;
          extraConfig = ''
            return 301 https://${cfg.domain}$request_uri;
          '';
        };
      };
    };

    security.acme.certs."${cfg.domain}".extraDomainNames =
      [ "www.${cfg.domain}" ];

    eilean.services.dns.zones.${cfg.zone}.records = [
      {
        name = "${cfg.domain}.";
        type = "CNAME";
        data = cfg.cname;
      }
      {
        name = "www.${cfg.domain}.";
        type = "CNAME";
        data = cfg.cname;
      }
    ];
  };
}
