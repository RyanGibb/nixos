{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom.gui;
in
{
  options.custom.gui.i3 = lib.mkEnableOption "i3";

  config = lib.mkIf cfg.i3 {
    home-manager.users.${config.custom.username} =
      { config, ... }:
      {
        config.custom.gui.i3.enable = true;
      };

    services.displayManager.ly.enable = true;
    services.xserver = {
      enable = true;
      windowManager.i3.enable = true;
    };

    environment.systemPackages = with pkgs; [
      i3
      xorg.xrandr
      arandr
      xss-lock
      xsecurelock
      redshift
      alacritty
      rofi
      dconf
      rofimoji
      dunst
      haskellPackages.greenclip
      xdotool
      xclip
      xf86_input_wacom
    ];

    # TODO read this
    # https://github.com/flatpak/xdg-desktop-portal/blob/1.18.1/doc/portals.conf.rst.in
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "*";
    };

    services.geoclue2.appConfig.redshift = {
      isAllowed = true;
      isSystem = false;
    };
  };
}
