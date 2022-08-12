{
  # TODO make zonefile nix derivation
  services.bind = {
    enable = true;
    cacheNetworks = [ "0.0.0.0/0" ];
    zones."gibbr.org" = {
      master = true;
      file = "/etc/nixos/modules/dns/gibbr.org.zone";
      # axfr zone transfer
      slaves = [
        "127.0.0.1"
      ];
    };
  };
}
