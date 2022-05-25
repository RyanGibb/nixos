{ pkgs, ... }:

{
  imports = [
    ./home.nix
  ];

  home.file = {
    ".zprofile".text = ''
      # Autostart i3 at login on TTY 1
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
      	exec xinit
      fi
    '';
    ".xinitrc".source = ./dotfiles/xinitrc;
  };

  xsession.windowManager.i3.enable = true;

  xdg.configFile = {
    # "rofi/".source = ./dotfiles/rofi;
    "i3/".source = ./dotfiles/i3;
    "i3blocks/".source = ./dotfiles/i3blocks;
  };
}
