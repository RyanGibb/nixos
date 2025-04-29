{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.custom;
in
{
  options.custom.nix-cache = {
    enable = lib.mkEnableOption "nix-cache";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "nix-cache.vpn.${config.networking.domain}";
    };
  };

  config = lib.mkIf cfg.nix-cache.enable {
    age.secrets."cache-priv-key.pem" = {
      file = ../secrets/cache-priv-key.pem.age;
      mode = "770";
      owner = "${config.systemd.services.nix-serve.serviceConfig.User}";
      group = "${config.systemd.services.nix-serve.serviceConfig.Group}";
    };
    services.nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets."cache-priv-key.pem".path;
    };

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.nix-cache.domain} = {
        forceSSL = true;
        locations."/".extraConfig = ''
          proxy_pass http://localhost:${toString config.services.nix-serve.port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };
}
