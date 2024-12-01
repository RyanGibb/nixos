{ config, lib, ... }:

let
  cfg = config.custom;
in
{
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
          "nix-cache.vpn.freumh.org:+jBJN2k1WO9wNr8uHQn7P4mT8c+VeP9uFGf+VTtfzHk="
        ];
      };
    };
  };
}
