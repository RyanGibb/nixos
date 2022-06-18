{ pkgs, lib, ... }:

let replacements = {
  wm = "i3";
  wmmsg = "i3-msg";
  rofi = "rofi";
  app_id = "class";
  preamble = ''
    font pango:Noto Sans Mono 12px
    set $bar_height 23px
  '';
  bar_extra = "";
  locked = "";
  polkit_gnome = "${pkgs.polkit_gnome}";
  wallpaper = ''
  '';
  set_wallpaper = ''
    feh --bg-scale $WALLPAPER_DIR/default
  '';
  locker = "i3lock";
  enable_output  = "xrandr --output $laptop_output --auto";
  disable_output = "xrandr --output $laptop_output --off";
  drun = "rofi -modi drun -show drun";
  run = "rofi -modi run -show run";
  dmenu = "rofi -dmenu -i -p";
  rofimoji = "rofimoji";
  displays = "arandr";
  bar = "i3bar";
}; in
let util = import ./util.nix { pkgs = pkgs; lib = lib; }; in
{
  imports = [
    ./home.nix
  ];

  home.file = {
    ".xinitrc".text = ''
      export XDG_SESSION_TYPE=x11
      export GDK_BACKEND=x11
      export DESKTOP_SESSION=plasma
      exec i3 &> ~/.i3_log
    '';
    ".zprofile".text = ''
      # Autostart at login on TTY 2
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 2 ]; then
      	exec startx
      fi
    '';
  };

  xdg.configFile  =
    let entries = {
      "i3/config".text =
        let src = ./dotfiles/wm/config.d; in
        let filenames = lib.attrsets.mapAttrsToList (name: value: "${src}/${name}") (builtins.readDir src); in
        (util.concatFilesReplace ([ ./dotfiles/wm/config ] ++ filenames) replacements);
      "i3blocks".source = ./dotfiles/i3blocks;
      "rofi/config.rasi".source = ./dotfiles/rofi.rasi;
    }; in
    (util.inDirReplace ./dotfiles/wm/scripts "i3/scripts" replacements) // entries;
}
