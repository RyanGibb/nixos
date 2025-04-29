{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom;
in
{
  options.custom.dict = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.dict {
    services.dictd.enable = true;

    environment.systemPackages = with pkgs; [ dict ];
  };
}
