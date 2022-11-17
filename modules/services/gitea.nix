{ pkgs, lib, config, ... }:

{
  services.nginx.virtualHosts."git.gibbr.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${builtins.toString config.services.gitea.httpPort}/";
    };
  };

  services.gitea = {
    enable = true;
    appName = "gitea gibbr.org";
    domain = "git.gibbr.org";
    rootUrl = "https://git.gibbr.org/";
    settings = {
      mailer = {
        ENABLED = true;
        MAILER_TYPE = "sendmail";
        FROM = "git@gibbr.org";
        SENDMAIL_PATH = "${pkgs.system-sendmail}/bin/sendmail";
        SENDMAIL_ARGS = "--";
      };
      repository.DEFAULT_BRANCH = "main";
      service.DISABLE_REGISTRATION = true;
    };
    database = {
      type = "postgres";
      passwordFile = "${config.secretsDir}/gitea-db";
      #user = "gitea";
      #name = "gitea";
      #createDatabase = true;
      #socket = "/run/postgresql";
    };
    #httpPort = 3000;
    #stateDir = "/var/lib/gitea";
  };

  # https://github.com/NixOS/nixpkgs/issues/103446
  systemd.services.gitea.serviceConfig = {
    ReadWritePaths = [ "/var/lib/postfix/queue/maildrop" ];
    NoNewPrivileges = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
    PrivateUsers = lib.mkForce false;
    ProtectHostname = lib.mkForce false;
    ProtectClock = lib.mkForce false;
    ProtectKernelTunables = lib.mkForce false;
    ProtectKernelModules = lib.mkForce false;
    ProtectKernelLogs = lib.mkForce false;
    RestrictAddressFamilies = lib.mkForce [ ];
    LockPersonality = lib.mkForce false;
    MemoryDenyWriteExecute = lib.mkForce false;
    RestrictRealtime = lib.mkForce false;
    RestrictSUIDSGID = lib.mkForce false;
    SystemCallArchitectures = lib.mkForce "";
    SystemCallFilter = lib.mkForce [];
  };
}
