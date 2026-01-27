{
  config,
  lib,
  ...
}:

let
  websiteLib = import ./lib/static-website.nix { inherit config lib; };
  mkStaticWebsite = websiteLib.mkStaticWebsite;

  ryanWebsite = mkStaticWebsite {
    name = "ryan";
    defaultRoot = "/var/www/ryan.freumh.org/";
    defaultIndex = "home.html index.html";
    customLocations = {
      locations."/atom.xml".extraConfig = ''
        return 301 $scheme://$host/home.xml;
      '';
      locations."/teapot".extraConfig = ''
        return 418;
      '';
      locations."/var/" = {
        alias = "/var/www/var/";
        extraConfig = ''
          add_header Strict-Transport-Security max-age=31536000 always;
          add_header X-Frame-Options SAMEORIGIN always;
          add_header X-Content-Type-Options nosniff always;
          add_header Referrer-Policy 'same-origin';
          add_header Content-Security-Policy "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;" always;
        '';
      };
      locations."~ \\.bib$" = {
        extraConfig = ''
          default_type text/plain;
        '';
      };
      locations."~ \\.md$" = {
        extraConfig = ''
          types { }
          default_type "text/markdown; charset=utf-8";
        '';
      };
    };
  };

  alecWebsite = mkStaticWebsite {
    name = "alec";
    defaultRoot = "/var/www/alec.freumh.org/";
    defaultIndex = "Homepage.html index.html";
  };
in
{
  imports = [
    ryanWebsite
    alecWebsite
  ];
}
