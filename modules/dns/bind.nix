{
  services.bind = {
    enable = true;
    extraOptions = ''
      dnssec-enable yes;
      dnssec-validation yes;
      dnssec-lookaside auto;
    '';
    zones."gibbr.org" = {
      master = true;
      file = "/etc/nixos/dns/gibbr.org.zone.signed";
      # axfr zone transfer
      slaves = [
        "127.0.0.1"
      ];
    };
  };
}