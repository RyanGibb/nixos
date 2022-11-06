{ config, ... }:

{
  imports = [
    ../mailserver/default.nix
  ];

  mailserver = {
    enable = true;
    fqdn = "mail.gibbr.org";
    domains = [ "gibbr.org" ];

    # A list of all login accounts. To create the password hashes, use
    # nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "super secret password" | cut -d: -f2
    loginAccounts = {
        "ryan@gibbr.org" = {
            hashedPasswordFile = "/etc/nixos/secrets/email_pswd";
            aliases = [
              "dns@gibbr.org"
              "postmaster@gibbr.org"
            ];
        };
        "misc@gibbr.org" = {
            hashedPasswordFile = "/etc/nixos/secrets/email_pswd";
            catchAll = [ "gibbr.org" ];
        };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = 3;

    localDnsResolver = false;
  };

  services.nginx.virtualHosts."${config.mailserver.fqdn}".extraConfig = ''
    return 301 $scheme://gibbr.org$request_uri;
  '';
}
