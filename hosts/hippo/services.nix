{
  pkgs,
  config,
  lib,
  eon,
  ...
}:

{
  security.acme.acceptTerms = true;
  services.nginx.enable = true;
  services.nginx.virtualHosts."enki.freumh.org" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = ''
        http://localhost:8000
      '';
      proxyWebsockets = true;
      extraConfig = ''
        # SSE-specific settings
        proxy_buffering off;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_connect_timeout 60s;

        # Forward headers
        proxy_set_header Connection "";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
      '';
    };
  };
  services.nginx.virtualHosts."packages.freumh.org" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = ''
        http://localhost:8080
      '';
      proxyWebsockets = true;
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    extensions = [
      pkgs.postgresql16Packages.pg_libversion
    ];
    dataDir = "/mnt/disk1/postgres/";
  };
}
