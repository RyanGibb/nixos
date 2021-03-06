{ pkgs, ... }:

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

  systemd.services.twitcher = {
    enable = true;
    description = "twitcher";
    serviceConfig = {
      ExecStart = "${pkgs.nodejs}/bin/node .";
      WorkingDirectory = "/var/www/twitcher";
    };
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment.PORT = "8080";
  };

  environment.systemPackages = with pkgs; [ nodejs ];
}
