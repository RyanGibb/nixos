{ pkgs, config, lib, ... }:

let cfg = config.custom.gui;
in {
  options.custom.gui.i3 = lib.mkEnableOption "i3";

  config = lib.mkIf cfg.i3 {
    home-manager.users.${config.custom.username} = { config, ... }: {
      config.custom.gui.i3.enable = true;
    };

    #services.displayManager.lightdm.enable = true;
    services.displayManager.defaultSession = "none+i3";
    services.xserver = {
      enable = true;
      windowManager.i3.enable = true;
    };

    environment.systemPackages = with pkgs; [
      i3-gaps
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

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      gtkUsePortal = false;
    };

    services.geoclue2.appConfig.redshift = {
      isAllowed = true;
      isSystem = false;
    };
  };
}
