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
    extraConfig = {
      # override localDomain
      LOCAL_DOMAIN = "gibbr.org";
      WEB_DOMAIN = "mastodon.gibbr.org";
      SMTP_FROM_ADDRESS = "mastodon@gibbr.org";
    };
  };
}
