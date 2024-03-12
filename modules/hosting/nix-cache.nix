{ config, pkgs, lib, ... }:

let cfg = config.hosting; in
{
  options.hosting.nix-cache.enable = lib.mkEnableOption "nix-cache";

  config = lib.mkIf cfg.nix-cache.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = "${config.custom.secretsDir}/cache-priv-key.pem";
    };

    services.nginx = {
      enable = true;
      virtualHosts."binarycache.${config.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".extraConfig = ''
          proxy_pass http://localhost:${toString config.services.nix-serve.port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };

    eilean.services.dns.zones.${config.networking.domain}.records = [
      {
        name = "binarycache";
        type = "CNAME";
        data = "vps";
      }
    ];
  };
}
