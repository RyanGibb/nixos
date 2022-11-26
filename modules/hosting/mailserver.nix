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
              "git@${domain}"
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

  dns.records = lib.mkIf (dns ? config) [
    {
      name = "mail";
      type = "A";
      data = config.hosting.serverIpv4;
    }
    {
      name = "mail";
      type = "AAAA";
      data = config.hosting.serverIpv6;
    }
    {
      name = "@";
      type = "MX";
      data = "10 mail";
    }
    {
      name = "@";
      type = "TXT";
      data = "\"v=spf1 a:mail.${config.networking.domain} -all\"";
    }
    {
      name = "mail._domainkey";
      ttl = 10800;
      type = "TXT";
      data = "\"v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC6YmYYvoFF7VqtGcozpVQa78aaGgZdvc5ZIHqzmkKdCBEyDF2FRbCEK4s2AlC8hhc8O4mSSe3S4AzEhlRgHXbU22GBaUZ3s2WHS8JJwZvWeTjsbXQwjN/U7xpkqXPHLH9IVfOJbHlp4HQmCAXw4NaypgkkxIGK0jaZHm2j6/1izQIDAQAB\"";
    }
    {
      name = "_dmarc";
      ttl = 10800;
      type = "TXT";
      data = "\"v=DMARC1; p=none\"";
    }
  ];
}
