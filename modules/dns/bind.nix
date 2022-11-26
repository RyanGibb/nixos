{ pkgs, lib, config, ... }:

let cfg = config.dns; in {
  services.bind = lib.mkIf (cfg.enable && cfg.server == "bind") {
    enable = true;
    # recursive resolver
    # cacheNetworks = [ "0.0.0.0/0" ];
    zones."${config.networking.domain}" = {
      master = true;
      file = "${cfg.zonefile}";
      # axfr zone transfer
      slaves = [
        "127.0.0.1"
      ];
    };
  };
}
