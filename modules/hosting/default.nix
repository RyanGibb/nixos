{ lib, ... }:

{
  options = {
    hosting.serverIpv4 = lib.mkOption {
      type = lib.types.str;
    };
    hosting.serverIpv6 = lib.mkOption {
      type = lib.types.str;
    };
  };
}
