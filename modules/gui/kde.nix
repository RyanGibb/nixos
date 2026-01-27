{ config, lib, ... }:

let
  cfg = config.custom.gui;
in
{
  options.custom.gui.kde = lib.mkEnableOption "kde";

  config = lib.mkIf cfg.kde {
    services.desktopManager.plasma6.enable = true;
    services.displayManager.ly.enable = true;
    services.displayManager.defaultSession = lib.mkDefault null;

    # screen reader
    services.orca.enable = false;
  };
}
