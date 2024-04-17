{ pkgs, config, lib, options, colour-guesser, ... }:

let cfg = config.custom.website.colour-guesser;
in {
  options = {
    custom.website.colour-guesser = {
      enable = lib.mkEnableOption "Colour Guesser";
      domain = lib.mkOption {
        type = lib.types.str;
        default = "colour-guesser.${config.networking.domain}";
      };
      cname = lib.mkOption {
        type = lib.types.str;
        default = null;
        description = ''
          CNAME to create DNS records for.
          Ignored if null
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme-eon.nginxCerts = [ cfg.domain ];
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        root =
          "${colour-guesser.packages.${pkgs.stdenv.hostPlatform.system}.default}";
      };
    };

    # requires dns module
    eilean.services.dns.zones.${config.networking.domain}.records = [
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
