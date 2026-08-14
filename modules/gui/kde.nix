{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.gui;
in
{
  options.custom.gui.kde = lib.mkEnableOption "kde";

  config = lib.mkIf cfg.kde {
    services.desktopManager.plasma6.enable = true;
    services.displayManager.ly.enable = true;

    environment.plasma6.excludePackages = [ pkgs.kdePackages.elisa ];

    # screen reader
    services.orca.enable = false;
  };
}
