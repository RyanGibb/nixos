{ config, lib, ... }:

with lib;

let
  recordOpts = {
    options = {
      name = mkOption {
        type = types.str;
      };
      ttl = mkOption {
        type = with types; nullOr int;
        default = null;
      };
      type = mkOption {
        type = types.str;
      };
      data = mkOption {
        type = types.str;
      };
    };
  };
in
{
  options.dns = {
    domain = mkOption {
      default = config.networking.domain;
    };
    ttl = mkOption {
      type = types.int;
      default = 3600; # 1hr
    };
    soa = {
      ns = mkOption {
        type = types.str;
        default = "ns1";
      };
      email = mkOption {
        type = types.str;
        default = "dns";
      };
      serial = mkOption {
        type = types.int;
        default = 2018011623;
      };
      refresh = mkOption {
        type = types.int;
        default = 3600; # 1hr
      };
      retry = mkOption {
        type = types.int;
        default = 15; # 15m
      };
      expire = mkOption {
        type = types.int;
        default = 1814400; # 21d
      };
      negativeCacheTtl = mkOption {
        type = types.int;
        default = 3600; # 1hr
      };
    };
    records = mkOption {
      type = with types; listOf (submodule recordOpts);
      default = [ ];
    };
  };
}
