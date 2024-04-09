{ pkgs, config, lib, ... }:

let cfg = config.custom;
in {
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
    users.groups.php = {};
    services.nginx = {
      enable = true;
      virtualHosts."${config.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/root" = let
          random-root = pkgs.writeScript "random-root.php" ''
            <?php
            $dir = '/var/roots/';
            $files = glob($dir . '/*.*');
            $file = $files[array_rand($files)];
            header('Content-Type: ' . mime_content_type($file));
            readfile($file);
            ?>
          '';
        in {
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
              <body style="background-color:#ebebeb; text-align: center;">
                <img src="root" style="width:100%; height:auto;">
                <a href="https://images.wur.nl/digital/collection/coll13" style="color: #040404">https://images.wur.nl/digital/collection/coll13</a>
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
        extraConfig = ''
          error_page 404 /404.html;
        '';
      };
    };
  };
}
