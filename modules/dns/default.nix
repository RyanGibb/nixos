{ config, lib, ... }:


let
  mkOption = lib.mkOption;
  recordOpts = {
    options = {
      name = {
        type = types.string;
      };
      ttl = {
        type = types.string;
      };
      type = {
        type = types.string;
      };
      data = {
        type = types.string;
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
        type = types.string;
        default = "ns1";
      };
      email = mkOption {
        type = types.string;
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
