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
    indexFiles = "home.html index";
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
          add_header Content-Security-Policy "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;" always;
          add_header Referrer-Policy 'same-origin';
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
    extraConfig = ''
      add_header Strict-Transport-Security max-age=31536000 always;
      add_header X-Frame-Options SAMEORIGIN always;
      add_header X-Content-Type-Options nosniff always;
      add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; frame-src 'self' https://watch.eeg.cl.cam.ac.uk;" always;
      add_header Referrer-Policy 'same-origin';
    '';
  };

  alecWebsite = mkStaticWebsite {
    name = "alec";
    defaultRoot = "/var/www/alec.freumh.org/";
    indexFiles = "Homepage.html index.html";
  };
in
{
  imports = [
    ryanWebsite
    alecWebsite
  ];
}
