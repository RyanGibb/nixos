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
      index ? "index.html",
      customLocations ? { },
      extraConfig ? "",
      enableDNS ? true,
    }:
    let
      cfg = config.custom.website.${name};
      logGroup = "${name}-log";
      logDir = "/var/log/nginx/${cfg.domain}";
      accessLog = "${logDir}/access.log";
      hasReaders = cfg.logReaders != [ ];
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
        index = mkOption {
          type = types.str;
          default = index;
          description = "Index files for the root location";
        };
        logReaders = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Users granted read-only access to this site's access logs.
            When non-empty the log directory is made setgid to a dedicated
            group (''${name}-log) containing these users.
          '';
        };
      };

      config = mkIf cfg.enable {
        security.acme-eon.nginxCerts = [ cfg.domain ];
        security.acme-eon.certs.${cfg.domain}.extraDomainNames = [ "www.${cfg.domain}" ];

        services.nginx = {
          enable = true;
          virtualHosts = {
            "${cfg.domain}" = lib.mkMerge [
              {
                forceSSL = true;
                root = cfg.root;
                locations."/".index = cfg.index;
                extraConfig = ''
                  error_page 403 =404 /404.html;
                  error_page 404 /404.html;
                  access_log ${accessLog};
                ''
                + extraConfig;
              }
              customLocations
            ];

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

        # Per-domain log directory; setgid to ${logGroup} when logReaders is set
        # so the named users can read this site's logs (and nothing else).
        systemd.tmpfiles.rules = [
          "d ${logDir} ${if hasReaders then "2750" else "0750"} nginx ${
            if hasReaders then logGroup else "nginx"
          } -"
        ];
        users.groups = mkIf hasReaders { "${logGroup}".members = cfg.logReaders; };
        services.logrotate.settings."${accessLog}" = {
          frequency = "weekly";
          rotate = 520;
          compress = true;
          delaycompress = true;
          missingok = true;
          su = "nginx ${if hasReaders then logGroup else "nginx"}";
          postrotate = "[ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`";
        };
      };
    };
}
