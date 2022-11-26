{ config, ... }:

{
  imports = [
    ../dns/default.nix
  ];

  dns.soa.serial = 2018011623;
  dns.records = builtins.concatMap (ns: [
    {
      name = "@";
      type = "NS";
      data = ns;
    }
    {
      name = ns;
      type = "A";
      data = config.hosting.serverIpv4;
    }
  ]) [ "ns1" "ns2" ] ++
  [
    {
      name = "www";
      type = "A";
      data = config.hosting.serverIpv4;
    }

    {
      name = "@";
      type = "A";
      data = config.hosting.serverIpv4;
    }
    {
      name = "@";
      type = "AAAA";
      data = config.hosting.serverIpv6;
    }
    {
      name = "vps";
      type = "A";
      data = config.hosting.serverIpv4;
    }
    {
      name = "vps";
      type = "AAAA";
      data = config.hosting.serverIpv6;
    }
    {
      name = "ryan";
      type = "CNAME";
      data = "vps";
    }
    {
      name = "www.ryan";
      type = "CNAME";
      data = "ryan";
    }
    {
      name = "twitcher";
      type = "CNAME";
      data = "vps";
    }
    {
      name = "git";
      type = "CNAME";
      data = "vps";
    }
    {
      name = "mastodon";
      type = "CNAME";
      data = "vps";
    }
    {
      name = "matrix";
      type = "CNAME";
      data = "vps";
    }

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

    {
      name = "pbindixel-4a.vpn";
      type = "A";
      data = "100.122.46.94";
    }
    {
      name = "dell-xps.vpn";
      type = "A";
      data = "100.92.111.117";
    }
    {
      name = "hp-pavilion.";
      type = "A";
      data = "100.91.12.120";
    }
    {
      name = "vps.vpn";
      type = "A";
      data = "100.88.115.118";
    }
    {
      name = "desktop.vpn";
      type = "A";
      data = "100.93.8.35";
    }
    {
      name = "rasp-pi.vpn";
      type = "A";
      data = "100.92.63.87";
    }

    {
      name = "@";
      type = "TXT";
      data = "google-site-verification=xM7L59imw-53rUPQIWD0VSrAEa94z2WAZ-FccXqX9V0";
    }

    {
      name = "@";
      type = "LOC";
      data = "52 12 40.4 N 0 5 31.9 E 22m 10m 10m 10m";
    }
  ];
}
