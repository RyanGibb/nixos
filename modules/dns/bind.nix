{ pkgs, ... }:

let zonefile = import ./gibbr.org.zone.nix { inherit pkgs; }; in
{
  services.bind = {
    enable = true;
    # recursive resolver
    # cacheNetworks = [ "0.0.0.0/0" ];
    zones."gibbr.org" = {
      master = true;
      file = "${zonefile}";
      # axfr zone transfer
      slaves = [
        "127.0.0.1"
      ];
    };
  };
}
