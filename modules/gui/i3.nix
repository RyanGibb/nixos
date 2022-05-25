{ pkgs, ... }:

{
  imports = [
    ./gui.nix
  ];
  
  home-manager.users.ryan = import ../home-manager/i3.nix;

  services.xserver = {
    enable = true;
    # displayManager.lightdm.enable = true;
    displayManager.defaultSession = "none+i3";
    windowManager.i3.enable = true;
  };

  xdg = {
    configFile = {
    "../.xinitrc".text = ''
      export XDG_SESSION_TYPE=x11
      export GDK_BACKEND=x11
      export DESKTOP_SESSION=plasma
      exec startplasma-x11
    '';
    };
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
