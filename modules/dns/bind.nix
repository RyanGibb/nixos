{ pkgs, lib, config, ... }:

let
  zonefile = import ./zonefile.nix { inherit pkgs lib config; };
in {
  imports = [ ./default.nix ];
  
  services.bind = {
    enable = true;
    # recursive resolver
    # cacheNetworks = [ "0.0.0.0/0" ];
    zones."${config.networking.domain}" = {
      master = true;
      file = "${zonefile}";
      # axfr zone transfer
      slaves = [
        "127.0.0.1"
      ];
    };
  };
}
