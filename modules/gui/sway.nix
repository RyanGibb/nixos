{ pkgs, config, lib, ... }:

let cfg = config.custom.gui;
in {
  options.custom.gui.sway = lib.mkEnableOption "sway";

  config = lib.mkIf cfg.sway {
    home-manager.users.${config.custom.username} = { config, ... }: {
      config.custom.gui.sway.enable = true;
    };

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = with pkgs; [
        jq
        swaylock
        swayidle
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
        dunst
        kanshi
      ];
    };

    # TODO read this
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
