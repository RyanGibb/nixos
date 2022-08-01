{ lib, config, ... }:

{
  options.vpnAddresses = lib.mkOption {
    default = {
      "vps" = "10.100.0.1";
      "dell-xps" = "10.100.0.2";
      "pixel-4a" = "10.100.0.3";
    };
  };
}