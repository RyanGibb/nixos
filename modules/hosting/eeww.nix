{ pkgs, config, lib, ... }:

with lib;

let cfg = config.services.eeww; in
{
  options = {
    services.eeww = {
      enable = mkEnableOption "eeww";
      domain = lib.mkOption {
        type = lib.types.str;
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8081;
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "eeww";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = cfg.user;
      };
    };
  };

  config = {
    # TODO use unix socket?
    services.nginx.virtualHosts."${cfg.domain}".locations."/".proxyPass = "http://localhost:${builtins.toString cfg.port}";

    systemd.services.eeww = {
      enable = true;
      description = "eeww";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.eeww}/main.exe -p 8081";
        WorkingDirectory = "${pkgs.ryan-website}";
        Restart = "always";
        RestartSec = "10s";
        User = "eeww";
        Group = "eeww";
      };
    };

    users.users."${cfg.user}" = {
      description = "eeww";
      useDefaultShell = true;
      group = cfg.group;
      isSystemUser = true;
    };

    users.groups."${cfg.group}" = {};
  };
}
