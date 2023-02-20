{ config, pkgs, lib, ... }:

let cfg = config.hosting; in
{
  options.hosting.nix-cache.enable = lib.mkEnableOption "nix-cache";

  config = lib.mkIf cfg.nix-cache.enable {
    services.nix-serve = {
      enable = true;
      # https://github.com/NixOS/nix/issues/7704
      package = pkgs.nix-serve.override {
        nix = pkgs.nixVersions.nix_2_12;
      };
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

    dns.records = [
      {
        name = "binarycache";
        type = "CNAME";
        data = "vps";
      }
    ];
  };
}
