{ pkgs, config, lib, ... }:

let cfg = config.services.owntracks-recorder;
in {
  options.services.owntracks-recorder = {
    enable = lib.mkEnableOption "Enable the Owntracks location tracker";
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 1883;
    };
    httpHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };
    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 8083;
    };
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO TLS and passwords if not behind VPN
    services.mosquitto = {
      enable = true;
      logType = [ "debug" ];
      listeners = [{
        port = cfg.port;
        address = cfg.host;
        acl = [ "topic readwrite #" ];
        omitPasswordAuth = true;
        users = { };
        settings = { allow_anonymous = true; };
      }];
    };

    systemd.services.owntracks-recorder = {
      description = "OwnTracks Recorder Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "mosquitto.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.owntracks-recorder}/bin/ot-recorder"
          + " --storage /var/lib/owntracks"
          + " --doc-root ${pkgs.owntracks-recorder.src}/docroot"
          + " --host ${cfg.host} --port ${builtins.toString cfg.port}"
          + " 'owntracks/#'";
        StateDirectory = "owntracks";
        Restart = "on-failure";
        User = "owntracks";
        Group = "owntracks";
      };
    };
    users.users.owntracks = {
      isSystemUser = true;
      group = "owntracks";
    };
    users.groups.owntracks = { };

    services.nginx = lib.mkIf (cfg.domain != null) {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        locations = {
          "/ws" = {
            proxyPass =
              "http://${cfg.httpHost}:${builtins.toString cfg.httpPort}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
          "/" = {
            proxyPass =
              "http://${cfg.httpHost}:${builtins.toString cfg.httpPort}/";
            recommendedProxySettings = true;
          };
          "/view/" = {
            proxyPass =
              "http://${cfg.httpHost}:${builtins.toString cfg.httpPort}/view/";
            recommendedProxySettings = true;
            # Chrome fix
            extraConfig = "proxy_buffering off;";
          };
          "/static/" = {
            proxyPass = "http://${cfg.httpHost}:${
                builtins.toString cfg.httpPort
              }/static/";
            recommendedProxySettings = true;
          };
          "/utils/" = {
            proxyPass =
              "http://${cfg.httpHost}:${builtins.toString cfg.httpPort}/utils/";
            recommendedProxySettings = true;
          };
        };
      };
    };
  };
}
