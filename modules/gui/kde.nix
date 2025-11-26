{ config, lib, ... }:

let
  cfg = config.custom.gui;
in
{
  options.custom.gui.kde = lib.mkEnableOption "kde";

  config = lib.mkIf cfg.kde {
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;

    i18n.inputMethod.fcitx5. plasma6Support = true;
  };
}
