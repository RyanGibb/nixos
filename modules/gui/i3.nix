{ pkgs, ... }:

{
  imports = [
    ./gui.nix
  ];
  
  home-manager.users.ryan = import ../home-manager/i3.nix;

  services.xserver = {
    enable = true;
    libinput.enable = true;
    desktopManager.xterm.enable = false;
    displayManager.lightdm.enable = true;
    displayManager.defaultSession = "none+i3";
    windowManager.i3.enable = true;
    layout = "us";
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
