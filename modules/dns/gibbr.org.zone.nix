{ pkgs, ... }:

pkgs.writeTextFile {
  name = "gibbr.org.zone";
  text = ''
    $ORIGIN gibbr.org.
    $TTL 3600
    @ IN SOA ns1 dns (
      2018011617 ; Serial
      3600       ; 1hr Refresh
      900        ; 15m Retry
      1814400    ; 21d Expire
      3600 )     ; 1hr Negative Cache TTL
    ;
    @               IN NS    ns1
    @               IN NS    ns2
    ns1             IN A     45.77.205.198
    ns2             IN A     45.77.205.198

    www             IN A     45.77.205.198

    @               IN A     45.77.205.198
    @               IN AAAA  2001:19f0:5:351a:5400:03ff:fede:b236 
    vps             IN A     45.77.205.198
    twitcher        IN CNAME vps

    mail            IN A     45.77.205.198
    mail            IN AAAA  2001:19f0:5:351a:5400:03ff:fede:b236
    @               IN MX    10 mail
    @               IN TXT   "v=spf1 a:mail.gibbr.org -all"
    mail._domainkey IN 10800 TXT "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC6YmYYvoFF7VqtGcozpVQa78aaGgZdvc5ZIHqzmkKdCBEyDF2FRbCEK4s2AlC8hhc8O4mSSe3S4AzEhlRgHXbU22GBaUZ3s2WHS8JJwZvWeTjsbXQwjN/U7xpkqXPHLH9IVfOJbHlp4HQmCAXw4NaypgkkxIGK0jaZHm2j6/1izQIDAQAB"
    _dmarc          IN 10800 TXT "v=DMARC1; p=none"

    pixel-4a.vpn    IN A     100.122.46.94
    dell-xps.vpn    IN A     100.92.111.117
    hp-pavilion.vpn IN A     100.91.12.120
    vps.vpn         IN A     100.125.253.71
    desktop.vpn     IN A     100.93.8.35
    rasp-pi.vpn     IN A     100.92.63.87

    @               IN TXT   google-site-verification=xM7L59imw-53rUPQIWD0VSrAEa94z2WAZ-FccXqX9V0

    @               IN LOC  52 12 40.4 N 0 5 31.9 E 22m 10m 10m 10m 
  '';
}