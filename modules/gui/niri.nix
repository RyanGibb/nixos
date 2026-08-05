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
  options.custom.gui.niri = lib.mkEnableOption "niri";

  config = lib.mkIf cfg.niri {
    home-manager.users.${config.custom.username} =
      { config, ... }:
      {
        config.custom.gui.niri.enable = true;
      };

    services.displayManager.ly.enable = true;

    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      clipman
      wtype
      gammastep
      waybar
      alacritty
      wofi
      wofi-emoji
      wdisplays
      wf-recorder
      grim
      slurp
      swappy
      wayfreeze
      dunst
      kanshi
      swaylock
      swayidle
      xwayland-satellite
    ];

    # https://github.com/flatpak/xdg-desktop-portal/blob/1.18.1/doc/portals.conf.rst.in
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "*";
    };

    services.geoclue2.appConfig.gammastep = {
      isAllowed = true;
      isSystem = false;
    };
  };
}
