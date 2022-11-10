{ lib, config, ... }:

{
  options.secretsDir = lib.mkOption {
    type = lib.types.path;
    default = "/etc/nixos/secrets";
  };
}
