{ pkgs, config, lib, ... }:

let cfg = config.personal;
in {
  options.personal.dict = lib.mkOption {
    type = types.bool;
    default = true;
  };

  config = lib.mkIf cfg.dict {
    services.dictd.enable = true;

    environment.systemPackages = with pkgs; [ dict ];
  };
}
