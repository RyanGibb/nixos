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
    index = "home.html index.html";
    customLocations = {
      locations."/atom.xml".extraConfig = ''
        return 301 $scheme://$host/home.xml;
      '';
      locations."/teapot".extraConfig = ''
        return 418;
      '';
      locations."/var/" = {
        alias = "/var/www/var/";
        index = "home.html index.html";
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
      # Content negotiation for HTML files - serve .md if Accept: text/markdown
      locations."~ ^(?!/var/)(.+)\\.html$" = {
        extraConfig = ''
          if ($http_accept ~* "text/markdown") {
            rewrite ^(.+)\.html$ $1.md last;
          }
        '';
      };
      locations."~ ^/var/(.*\\.md)$" = {
        alias = "/var/www/var/$1";
        extraConfig = ''
          types { }
          default_type "text/markdown; charset=utf-8";
        '';
      };
      locations."~ ^(?!/var/).*\\.md$" = {
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
      add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data:; frame-src 'self' https://watch.eeg.cl.cam.ac.uk;" always;
      add_header Referrer-Policy 'same-origin';
      add_header Vary Accept always;
    '';
  };

  alecWebsite = mkStaticWebsite {
    name = "alec";
    defaultRoot = "/var/www/alec.freumh.org/";
    index = "Homepage.html index.html";
  };
in
{
  imports = [
    ryanWebsite
    alecWebsite
  ];
}
