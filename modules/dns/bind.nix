{
  # TODO make zonefile nix derivation
  services.bind = {
    enable = true;
    zones."gibbr.org" = {
      master = true;
      file = "/etc/nixos/modules/dns/gibbr.org.zone.signed";
      # axfr zone transfer
      slaves = [
        "127.0.0.1"
      ];
    };
  };
}
