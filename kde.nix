{
  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.layout = "gb";

  home-manager = {
    useGlobalPkgs = true;
    users.ryan = { 
      xdg = {
        configFile = {
        "../.xinitrc".text = ''
          export XDG_SESSION_TYPE=x11
          export GDK_BACKEND=x11
          export DESKTOP_SESSION=plasma
          exec startplasma-x11
        '';
        # stop kde overriding icon pack
        "../.gtkrc-2.0".text = '''';
        };
      };
    };
  };
}