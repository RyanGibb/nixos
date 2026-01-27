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
  options.custom.gui.sway = lib.mkEnableOption "sway";

  config = lib.mkIf cfg.sway {
    home-manager.users.${config.custom.username} =
      { config, ... }:
      {
        config.custom.gui.sway.enable = true;
      };

    services.displayManager.ly.enable = true;
    services.displayManager.defaultSession = lib.mkDefault "sway";

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraOptions = [
        "--unsupported-gpu"
      ];
      extraSessionCommands = ''
        source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
        export QT_QPA_PLATFORM="wayland"
        export SDL_VIDEODRIVER="wayland"
        export MOZ_ENABLE_WAYLAND=1
        export MOZ_DBUS_REMOTE=1
        export QT_STYLE_OVERRIDE="Fusion"
        export NIXOS_OZONE_WL=1

        # for intellij
        export _JAVA_AWT_WM_NONREPARENTING=1

        # for screensharing
        export XDG_SESSION_TYPE="wayland"
        export XDG_CURRENT_DESKTOP="sway"
      '';
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
