{ pkgs, lib, ... }:

let replacements = {
  wm = "i3";
  wmmsg = "i3-msg";
  rofi = "rofi";
  app_id = "class";
  bar_extra = "";
  locked = "";
  polkit_gnome = "${pkgs.polkit_gnome}";
  geoclue2 = "${pkgs.geoclue2}";
  wallpaper = ''
  '';
  set_wallpaper = ''
    feh --bg-fill $WALLPAPER_DIR/default
  '';
  locker = "xsecurelock";
  enable_output  = "xrandr --output $laptop_output --auto";
  disable_output = "xrandr --output $laptop_output --off";
  drun = "rofi -modi drun -show drun";
  run = "rofi -modi run -show run";
  dmenu = "rofi -dmenu -i -p";
  rofimoji = "rofimoji";
  displays = "arandr";
  bar = "i3bar";
  notification_deamon = "dunst";
  redshift = "redshift-gtk";
}; in
let util = import ./util.nix { pkgs = pkgs; lib = lib; }; in
{
  imports = [
    ./home.nix
  ];

  # TODO
  # idling

  home.pointerCursor.x11.enable = true;

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
      "redshift/redshift.conf".text = ''
        [redshift]
        dawn-time=06:00-07:00
        dusk-time=18:00-19:00
      '';
      "dunst/dunstrc".source = ./dotfiles/dunst;
      "i3/config".text =
        let wmFilenames = util.listFilesInDir ./dotfiles/wm/config.d; in
        let i3Filenames = util.listFilesInDir ./dotfiles/wm/i3; in
        (util.concatFilesReplace ([ ./dotfiles/wm/config ] ++ wmFilenames ++ i3Filenames) replacements);
      "i3blocks".source = ./dotfiles/i3blocks;
      "rofi/config.rasi".source = ./dotfiles/rofi.rasi;
    }; in
    (util.inDirReplace ./dotfiles/wm/scripts "i3/scripts" replacements) // entries;
}
