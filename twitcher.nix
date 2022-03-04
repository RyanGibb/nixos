{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."twitcher.gibbr.org" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
      };
    };
  };

  systemd.services.foo = {
    enable = true;
    description = "twitcher";
    unitConfig = {
      Type = "simple";
      # ...
    };
    serviceConfig = {
      ExecStart = "/home/ryan/twitcher";
      # ...
    };
    wantedBy = [ "multi-user.target" ];
    # ...
  };

  environment.systemPackages = [ nodejs ]

}

