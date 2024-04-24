{ pkgs, config, lib, options, ... }:

let
  cfg = config.custom.website.xkcd-colour-game;
  pkg = pkgs.buildNpmPackage rec {
    name = "xkcd_colour_game";
  
    src = pkgs.fetchFromGitHub {
      owner = "meands";
      repo = name;
      rev = "263de3237a458fdf04c52f81b5b131048feb5b64";
      hash = "sha256-aBbQl66weAQpPCXJdruymXBMspWjsa1IvpvXpYEKSsU=";
    };
  
    npmDepsHash = "";
  };
in {
  options = {
    custom.website.xkcd-colour-game = {
      enable = lib.mkEnableOption "XKCD Colour Game";
      domain = lib.mkOption {
        type = lib.types.str;
        default = "xkcd-colour-game.${config.networking.domain}";
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
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;
        root = "${pkg}";
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
