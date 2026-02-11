{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom;
in
{
  options.custom.freumh.enable = lib.mkEnableOption "freumh";

  config = lib.mkIf cfg.freumh.enable {
    security.acme = {
      defaults.email = "${config.custom.username}@${config.networking.domain}";
      acceptTerms = true;
    };

    services.phpfpm.pools.freumh = {
      user = "php";
      group = "php";
      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.max_requests" = 500;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 5;
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
      };
      phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
    };
    users.users.php = {
      isSystemUser = true;
      group = "php";
    };
    users.groups.php = { };

    security.acme-eon.nginxCerts = [ config.networking.domain ];
    services.nginx = {
      enable = true;
      virtualHosts."${config.networking.domain}" = {
        forceSSL = true;
        extraConfig = ''
          error_page 404 /404.html;
          add_header Strict-Transport-Security max-age=31536000 always;
          add_header X-Frame-Options SAMEORIGIN always;
          add_header X-Content-Type-Options nosniff always;
          add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' blob:;" always;
          add_header Referrer-Policy 'same-origin';
        '';
        locations."/root" =
          let
            random-root = pkgs.writeScript "random-root.php" ''
              <?php
              $dir = '/var/roots/';
              $files = glob($dir . '/*.*');
              $file = $files[array_rand($files)];
              header('Content-Type: ' . mime_content_type($file));
              header('X-Id: ' . pathinfo($file, PATHINFO_FILENAME));
              readfile($file);
              ?>
            '';
          in
          {
            extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools.freumh.socket};
              include ${pkgs.nginx}/conf/fastcgi_params;
              fastcgi_param SCRIPT_FILENAME ${random-root};
            '';
          };
        locations."/index.html".root = pkgs.writeTextFile {
          name = "freumh";
          text = ''
            <html>
              <head>
                <style>
                  body, html {
                    height: 100%;
                    margin: 0;
                  }
                  .bg {
                    height: 100%;
                    background-position: center;
                    background-repeat: no-repeat;
                    background-size: cover;
                  }
                  @media (prefers-color-scheme: dark) {
                    body {
                      filter: invert(1);
                    }
                  }
                </style>
                <script>
                  function fetchImage() {
                    fetch('root')
                    .then(response => {
                      const id = response.headers.get('X-Id');
                      const link = document.getElementById('link');
                      link.href = `https://images.wur.nl/digital/collection/coll13/id/''${id}/rec/1`;
                      return response.blob();
                    })
                    .then(blob => {
                      const url = URL.createObjectURL(blob);
                      document.getElementById('bg').style.backgroundImage = `url(''${url})`;
                    })
                    .catch(error => {
                      console.error('Error fetching image:', error);
                    });
                  }
                  window.onload = fetchImage;
                </script>
              </head>
              <body style="background-color:#ebebeb; text-align: center;">
                <a id="link" style="color: #040404">
                  <div id="bg" class="bg"></div>
                </a>
              </body>
            </pre>
          '';
          destination = "/index.html";
        };
        locations."/404.html".extraConfig = ''
          return 200 "";
        '';
        locations."/.well-known/security.txt".root = pkgs.writeTextFile {
          name = "freumh-security.txt";
          text = ''
            Contact: mailto:security@freumh.org
          '';
          destination = "/.well-known/security.txt";
        };
      };
    };
  };
}
