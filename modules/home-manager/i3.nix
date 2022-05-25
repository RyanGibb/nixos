{ pkgs, ... }:

{
  imports = [
    ./home.nix
  ];

  xsession.windowManager.i3.enable = true;

  home.file = {
    ".xinitrc".text = ''
      export XDG_SESSION_TYPE=x11
      export GDK_BACKEND=x11
      export DESKTOP_SESSION=plasma
      exec i3
    '';
    ".zprofile".text = ''
      # Autostart at login on TTY 1
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
      	exec xinit
      fi
    '';
  };

  xdg.configFile = {
    # "rofi/".source = ./dotfiles/rofi;
    "i3/".source = ./dotfiles/i3;
    "i3blocks/".source = ./dotfiles/i3blocks;
  };
}
