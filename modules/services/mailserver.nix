{ config, ... }:

let domain = config.networking.domain; in
{
  imports = [
    ../mailserver/default.nix
  ];

  mailserver = {
    enable = true;
    fqdn = "mail.${domain}";
    domains = [ "${domain}" ];

    # A list of all login accounts. To create the password hashes, use
    # nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "super secret password" | cut -d: -f2
    loginAccounts = {
        "${config.custom.username}@${domain}" = {
            hashedPasswordFile = "${config.secretsDir}/email-pswd";
            aliases = [
              "dns@${domain}"
              "postmaster@${domain}"
            ];
        };
        "misc@${domain}" = {
            hashedPasswordFile = "${config.secretsDir}/email-pswd";
            aliases = [
              "gitea@${domain}"
              "mastodon@${domain}"
            ];
            catchAll = [ "${domain}" ];
        };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = 3;

    localDnsResolver = false;
  };

  services.nginx.virtualHosts."${config.mailserver.fqdn}".extraConfig = ''
    return 301 $scheme://${domain}$request_uri;
  '';
}
