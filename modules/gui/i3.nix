{ pkgs, ... }:

{
  imports = [
    ./default.nix
  ];
  
  home-manager.users.ryan = import ../home-manager/i3.nix;

  services.xserver = {
    enable = true;
    # displayManager.lightdm.enable = true;
    displayManager.defaultSession = "none+i3";
    windowManager.i3.enable = true;
  };

  environment.systemPackages = with pkgs; [
    i3blocks
    redshift
    alacritty
    rofi
    dconf
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    gtkUsePortal = false;
  };
}
