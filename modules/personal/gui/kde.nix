{
  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
  };

  home-manager.users.${config.custom.username}.home.file = {
    ".xinitrc".text = ''
      export XDG_SESSION_TYPE=x11
      export GDK_BACKEND=x11
      export DESKTOP_SESSION=plasma
      exec startplasma-x11
    '';
  };
}
