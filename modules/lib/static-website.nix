{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
in
{
  mkStaticWebsite =
    {
      name,
      defaultDomain ? "${name}.${config.networking.domain}",
      defaultZone ? config.networking.domain,
      defaultRoot,
      defaultIndex ? "index.html",
      customLocations ? { },
      enableDNS ? true,
    }:
    let
      cfg = config.custom.website.${name};
    in
    {
      options.custom.website.${name} = {
        enable = mkEnableOption "${name}'s website";
        zone = mkOption {
          type = types.str;
          default = defaultZone;
          description = "Parent DNS zone for the website";
        };
        domain = mkOption {
          type = types.str;
          default = defaultDomain;
          description = "Primary domain for the website";
        };
        cname = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            CNAME to create DNS records for.
            Ignored if null
          '';
        };
        root = mkOption {
          type = types.either types.path types.package;
          default = defaultRoot;
          description = "Root directory or package for the website";
        };
        indexFiles = mkOption {
          type = types.str;
          default = defaultIndex;
          description = "Index files for the root location";
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
              root = cfg.root;
              locations."/".index = cfg.indexFiles;
              extraConfig = ''
                error_page 403 =404 /404.html;
                error_page 404 /404.html;
                access_log /var/log/nginx/${cfg.domain}.log;
              '';
            }
            // customLocations;

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

        eilean.services.dns.zones.${cfg.zone}.records = mkIf enableDNS [
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
    };
}
