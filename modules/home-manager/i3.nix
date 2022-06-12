{ pkgs, ... }:

{
  imports = [
    ./home.nix
  ];

  home.file = {
    ".xinitrc".text = ''
      export XDG_SESSION_TYPE=x11
      export GDK_BACKEND=x11
      export DESKTOP_SESSION=plasma
      exec i3
    '';
    ".zprofile".text = ''
      # Autostart at login on TTY 2
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 2 ]; then
      	exec xinit
      fi
    '';
  };

  xdg.configFile = {
    "i3/".source = ./dotfiles/i3;
    "i3blocks".source = ./dotfiles/i3blocks;
    "rofi/config.rasi".source = ./dotfiles/rofi.rasi;
  };
}
