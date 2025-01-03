{
  pkgs,
  config,
  lib,
  fn06-website,
  ...
}:

with lib;

let
  cfg = config.custom.website.fn06;
in
{
  options = {
    custom.website.fn06 = {
      enable = mkEnableOption "fn06's website";
      domain = mkOption {
        type = types.str;
        default = "fn06.${config.networking.domain}";
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
          root = "${fn06-website.packages.${pkgs.stdenv.hostPlatform.system}.default}";
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
  };
}
