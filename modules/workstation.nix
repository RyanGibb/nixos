{ pkgs, config, lib, ... }@inputs:

let cfg = config.custom;
in {
  options.custom.workstation = lib.mkEnableOption "custom";

  config = lib.mkIf cfg.workstation {
    services.localtimed.enable = true;
    services.geoclue2.enable = true;
  };
}
