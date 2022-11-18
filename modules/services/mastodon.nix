{ pkgs, config, ... }:

{
  services.mastodon = {
    enable = true;
    # used for proxy
    localDomain = "mastodon.gibbr.org";
    configureNginx = true;
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
    };
  };
}
