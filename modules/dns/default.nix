{ config, lib, ... }:

let mkOption = lib.mkOption; in
{
  options.dns = {
    domain = mkOption {
      default = config.networking.domain;
    };
    ttl = mkOption {
      default = "3600"; # 1hr
    };
    soa = {
      ns = mkOption {
        default = "ns1";
      };
      email = mkOption {
        default = "dns";
      };
      serial = mkOption {
        default = "2018011623";
      };
      refresh = mkOption {
        default = "3600"; # 1hr
      };
      retry = mkOption {
        default = "15"; # 15m
      };
      expire = mkOption {
        default = "1814400"; # 21d
      };
      negativeCacheTtl = mkOption {
        default = "3600"; # 1hr
      };
    };
    records = mkOption {
      default =
        builtins.concatMap (ns: [
          {
            name = "@";
            type = "NS";
            data = ns;
          }
          {
            name = ns;
            type = "A";
            data = config.custom.serverIpv4;
          }
        ]) [ "ns1" "ns2" ]
        ;# ++ [
          
        #]
    };
  };
}
