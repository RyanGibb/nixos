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

    # keyd: modal mouse layer, enter with Meta+Shift+P, Escape exits.
    # Ports the sway "mouse" mode; wlrctl calls run in the active user's
    # session so they inherit WAYLAND_DISPLAY. Enabling keyd overrides
    # sway's own `mode "mouse"` binding on Meta+Shift+P.
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            "meta+shift+p" = "layer(mouse)";
          };
          "mouse:overlay" = {
            h = "command(wlrctl pointer move -20 0)";
            j = "command(wlrctl pointer move 0 20)";
            k = "command(wlrctl pointer move 0 -20)";
            l = "command(wlrctl pointer move 20 0)";
            n = "command(wlrctl pointer scroll 0 -20)";
            m = "command(wlrctl pointer scroll 20 0)";
            "comma" = "command(wlrctl pointer scroll -20 0)";
            "dot" = "command(wlrctl pointer scroll 0 20)";
            s = "command(wlrctl pointer click left)";
            d = "command(wlrctl pointer click middle)";
            f = "command(wlrctl pointer click right)";
            escape = "layer(mouse)";
            enter = "layer(mouse)";
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      wlr-which-key
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
