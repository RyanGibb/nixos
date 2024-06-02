{ config, lib, ... }:

let cfg = config.custom;
in {
  options.custom.useNixCache = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.useNixCache {
    nix = {
      settings = {
        substituters = [
          "https://cache.nixos.org?priority=100"
          "https://nix-cache.vpn.freumh.org?priority=10"
        ];
        trusted-public-keys = [
          "nix-cache.vpn.freumh.org:Go6ACovVBhR4P6Ug3DsE0p0DIRQtkIBHui1DGM7qK5c="
        ];
      };
    };
  };
}
