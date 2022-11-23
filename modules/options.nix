{ lib }:

{
  options = {
    custom.username = lib.mkOption {
      type = lib.types.str;
    };
    custom.serverIpv4 = lib.mkOption {
      type = lib.types.str;
    };
    custom.serverIpv6 = lib.mkOption {
      type = lib.types.str;
    }
  };
}