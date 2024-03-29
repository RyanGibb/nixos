{ pkgs, config, lib, ... }:

let cfg = config.hosting; in
{
  options.hosting.freumh.enable = lib.mkEnableOption "freumh";
  
  config = lib.mkIf cfg.freumh.enable {
    security.acme = {
      defaults.email = "${config.eilean.username}@${config.networking.domain}";
      acceptTerms = true;
    };

    services.nginx.virtualHosts."${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/index.html".root = pkgs.writeTextFile {
        name = "freumh";
        text = ''
  <html>
  <body>
  <pre>
        ||
        \\
  _      ||    __
  \    / \\  /  \
    \__/   \\/
            \\      __
      _    / \\    /  \_/
    _/ \  ||   \__/
        \//     \
        //       \
        ||        \_
  </html>
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
}
