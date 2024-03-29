{ pkgs, config, lib, ... }:

let cfg = config.personal.gui; in
{
  options.personal.gui.sway = lib.mkEnableOption "sway";

  config = lib.mkIf cfg.sway {
    home-manager.users.${config.custom.username} = import ../home/sway.nix;

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = with pkgs; [
        jq
        swaylock
        swayidle
        i3blocks
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
        mako
        kanshi
      ];
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      gtkUsePortal = false;
    };

    services.geoclue2.appConfig.gammastep = {
      isAllowed = true;
      isSystem = false;
    };
  };
}
