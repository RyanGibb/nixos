{ pkgs, config, ... }:

{
  services.nginx.virtualHosts."gitea.gibbr.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${builtins.toString config.services.gitea.httpPort}/";
    };
  };

  services.gitea = {
    enable = true;
    appName = "gitea | gibbr.org";
    domain = "gitea.gibbr.org";
    rootUrl = "https://gitea.gibbr.org/";
    settings = {
      mailer = {
        ENABLED = true;
        MAILER_TYPE = "sendmail";
        FROM = "gitea@gibbr.org";
        SENDMAIL_PATH = "${pkgs.system-sendmail}/bin/sendmail";
      };
      repository.DEFAULT_BRANCH = "main";
    };
    database = {
      type = "postgres";
      passwordFile = "${config.secretsDir}/gitea-db";
    } //
    # below isn't neccasary, but including for the sake of clarity
    {
      user = "gitea";
      name = "gitea";
      createDatabase = true;
      socket = "/run/postgresql";
    };
    httpPort = 3000;
    stateDir = "/var/lib/gitea";
  };
}
