{ pkgs, config, ... }:

{
  imports = [
    ./default.nix
  ];
  
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
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    gtkUsePortal = false;
  };
}
