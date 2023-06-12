{ pkgs, lib, wallpapers, ... }:

let replacements = {
  wm = "sway";
  wmmsg = "swaymsg";
  rofi = "wofi";
  app_id = "app_id";
  bar_extra = ''
    icon_theme Papirus
  '';
  locked = "--locked";
  polkit_gnome = "${pkgs.polkit_gnome}";
  set_wallpaper = ''
    swaymsg "output * bg $HOME/.cache/wallpaper fill #2e3440"
  '';
  locker = "swaylock -f -i $HOME/.cache/wallpaper";
  enable_output  = "swaymsg output $laptop_output enable";
  disable_output = "swaymsg output $laptop_output disable";
  drun = "wofi -i --show drun --allow-images -a";
  run = "wofi -i --show run";
  dmenu = "wofi -d -i -p";
  rofimoji = ''
    rofimoji --selector wofi --skin-tone neutral --prompt "" -a copy
  '';
  displays = "wdisplays";
  bar = "swaybar";
  notification_deamon = "mako";
  redshift = "gammastep-indicator -r";
}; in
let util = import ./util.nix { inherit pkgs lib; }; in
{
  imports = [
    ./default.nix
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = 1;
    MOZ_DBUS_REMOTE = 1;
    QT_STYLE_OVERRIDE = "Fusion";
    TERMINAL = "alacritty";
    WLR_NO_HARDWARE_CURSORS = 1;
    NIXOS_OZONE_WL = 1;

    # for intellij
    _JAVA_AWT_WM_NONREPARENTING = 1;

    # for screensharing
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "sway";

    WALLPAPER_DIR = wallpapers;
  };

  home.file = {
    ".zprofile".text = ''
      # Autostart sway at login on TTY 1
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
        source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
      	exec sway -d 2> $HOME/.sway_log
      fi
    '';
    ".profile".text = ''
      source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    '';
  };

  xdg.configFile  =
    let entries = {
      "gammastep/config.ini".text = ''
        [general]
        dawn-time=06:00-07:00
        dusk-time=18:00-19:00
      '';
      "fusuma/config.yml".source = ./fusuma.yml;
      "kanshi/config".source = ./kanshi;
      "mako/config".source = ./mako;
      "swaylock/config".source = ./swaylock;
      "wofi/style.css".source = ./wofi.css;
      "swappy/config".text = ''
        [Default]
        save_dir=$HOME/pictures/capture/
        save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
      '';
      "sway/config".text =
        let wmFilenames = util.listFilesInDir ./wm/config.d; in
        let swayFilenames = util.listFilesInDir ./wm/sway; in
        (util.concatFilesReplace ([ ./wm/config ] ++ wmFilenames ++ swayFilenames) replacements);
      "i3blocks".source = ./i3blocks;
    }; in
    (util.inDirReplace ./wm/scripts "sway/scripts" replacements) // entries;
}
