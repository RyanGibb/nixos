{ pkgs, config, ... }:

{
  services.mastodon = {
    enable = true;
    enableUnixSocket = false;
    webProcesses = 1;
    webThreads = 3;
    sidekiqThreads = 5;
    smtp = {
      #createLocally = false;
      user = "misc@gibbr.org";
      port = 465;
      host = "mail.gibbr.org";
      authenticate = true;
      passwordFile = "${config.secretsDir}/email-pswd-unhashed";
      fromAddress = "mastodon@gibbr.org";
    };
    extraConfig = {
      # override localDomain
      LOCAL_DOMAIN = "gibbr.org";
      WEB_DOMAIN = "mastodon.gibbr.org";

      # https://peterbabic.dev/blog/setting-up-smtp-in-mastodon/
      SMTP_SSL="true";
      SMTP_ENABLE_STARTTLS="false";
      SMTP_OPENSSL_VERIFY_MODE="none";

      SINGLE_USER_MODE = true;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      # relies on gibbr.org being set up
      "gibbr.org".locations."/.well-known/host-meta".extraConfig = ''
        return 301 https://mastodon.gibbr.org$request_uri;
      '';
      "mastodon.gibbr.org" = {
        root = "${config.services.mastodon.package}/public/";
        forceSSL = true;
        enableACME = true;

        locations."/system/".alias = "/var/lib/mastodon/public-system/";

        locations."/" = {
          tryFiles = "$uri @proxy";
        };

        locations."@proxy" = {
          proxyPass = "http://127.0.0.1:${builtins.toString config.services.mastodon.webPort}";
          proxyWebsockets = true;
        };

        locations."/api/v1/streaming/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString config.services.mastodon.streamingPort}/";
          proxyWebsockets = true;
        };
      };
    };
  };
}
