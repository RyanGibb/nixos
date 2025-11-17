{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.custom.website.ryan;
in
{
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
    security.acme-eon.nginxCerts = [ cfg.domain ];
    security.acme-eon.certs.${cfg.domain}.extraDomainNames = [ "www.${cfg.domain}" ];

    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.domain}" = {
          forceSSL = true;
          root = "/var/www/ryan.freumh.org/";
          locations."/".index = "home.html index.html";
          locations."/atom.xml".extraConfig = ''
            return 301 $scheme://$host/home.xml;
          '';
          locations."/teapot".extraConfig = ''
            return 418;
          '';
          locations."/var/" = {
            alias = "/var/www/var/";
            extraConfig = ''
              add_header Strict-Transport-Security max-age=31536000 always;
              add_header X-Frame-Options SAMEORIGIN always;
              add_header X-Content-Type-Options nosniff always;
              add_header Referrer-Policy 'same-origin';
              add_header Content-Security-Policy "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;" always;
            '';
          };
          locations."~ \\.bib$" = {
            extraConfig = ''
              default_type text/plain;
            '';
          };
          locations."~ \\.md$" = {
            extraConfig = ''
              types { }
              default_type "text/markdown; charset=utf-8";
            '';
          };
          extraConfig = ''
            error_page 403 =404 /404.html;
            error_page 404 /404.html;
            # see http://nginx.org/en/docs/http/ngx_http_log_module.html#access_log
            access_log /var/log/nginx/${cfg.domain}.log;
          '';
        };
        "www.${cfg.domain}" =
          let
            certDir = config.security.acme-eon.certs.${cfg.domain}.directory;
          in
          {
            forceSSL = true;
            sslCertificate = "${certDir}/fullchain.pem";
            sslCertificateKey = "${certDir}/key.pem";
            sslTrustedCertificate = "${certDir}/chain.pem";
            extraConfig = ''
              return 301 https://${cfg.domain}$request_uri;
            '';
          };
      };
    };

    eilean.services.dns.zones.${cfg.zone}.records = [
      {
        name = "${cfg.domain}.";
        type = "CNAME";
        value = cfg.cname;
      }
      {
        name = "www.${cfg.domain}.";
        type = "CNAME";
        value = cfg.cname;
      }
    ];
  };
}
