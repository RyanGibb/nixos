{
  config,
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
    # nix-serve runs under DynamicUser, so its user only exists while the unit is
    # up; activation stops it before agenixChown, so chown to it fails. Grant
    # access through a static group instead.
    users.groups.nix-serve-secrets = { };

    age.secrets."cache-priv-key.pem" = {
      file = ../secrets/cache-priv-key.pem.age;
      mode = "0440";
      group = "nix-serve-secrets";
    };
    services.nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets."cache-priv-key.pem".path;
    };
    systemd.services.nix-serve.serviceConfig.SupplementaryGroups = [ "nix-serve-secrets" ];

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
