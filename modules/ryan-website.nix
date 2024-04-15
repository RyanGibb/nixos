{ pkgs, config, lib, ryan-website, ... }:

with lib;

let cfg = config.custom.website.ryan;
in {
  options = {
    custom.website.ryan = {
      enable = mkEnableOption "ryan's website";
      zone = mkOption {
        type = types.str;
        default = "${config.networking.domain}";
      };
      domain = mkOption {
        type = types.str;
        default = "ryan.${config.networking.domain}";
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
            "${ryan-website.packages.${pkgs.stdenv.hostPlatform.system}.default}";
          locations."/teapot".extraConfig = ''
            return 418;
          '';
          locations."/var/".extraConfig = ''
            alias /var/website/;
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
