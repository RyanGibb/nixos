{ pkgs, config, lib, ... }:

let cfg = config.personal.gui; in
{
  options.personal.gui.i3 = lib.mkEnableOption "i3";

  config = lib.mkIf cfg.i3 {
    home-manager.users.${config.custom.username} = import ../home/i3.nix;

    services.xserver = {
      enable = true;
      # displayManager.lightdm.enable = true;
      displayManager.defaultSession = "none+i3";
      windowManager.i3.enable = true;
    };

    environment.systemPackages = with pkgs; [
      i3-gaps
      xorg.xrandr
      arandr
      xss-lock
      xsecurelock
      i3blocks
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
  };
}
