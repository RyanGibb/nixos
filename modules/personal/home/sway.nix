{ pkgs, lib, ... }:

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
  locker = "swaylock -f -i $WALLPAPER";
  enable_output  = "swaymsg output $laptop_output enable";
  disable_output = "swaymsg output $laptop_output disable";
  drun = "wofi -i --show drun --allow-images -a";
  run = "wofi -i --show run";
  dmenu = "wofi -d -i -p";
  displays = "wdisplays";
  bar = "swaybar";
  notification_deamon = "mako";
  i3-workspace-history = "${pkgs.i3-workspace-history}";
  i3-workspace-history-args = "-sway";
}; in
let util = import ./util.nix { inherit pkgs lib; }; in
{
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
  };

  home.file.".zprofile".text = ''
    # Autostart sway at login on TTY 1
    if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
      source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
    	exec sway -d 2> $HOME/.sway_log
    fi
  '';

  xdg.configFile  =
    let entries = {
      "fusuma/config.yml".source = ./fusuma.yml;
      "kanshi/config".source = ./kanshi;
      "mako/config".source = ./mako;
      "swaylock/config".source = ./swaylock;
      "wofi/style.css".source = ./wofi.css;
      "swappy/config".text = ''
        [Default]
        save_dir=$HOME/capture/capture/
        save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
      '';
      "sway/config".text =
        let wmFilenames = util.listFilesInDir ./wm/config.d; in
        let swayFilenames = util.listFilesInDir ./wm/sway; in
        (util.concatFilesReplace ([ ./wm/config ] ++ wmFilenames ++ swayFilenames) replacements);
      "i3blocks".source = ./i3blocks;
    }; in
    (util.inDirReplace ./wm/scripts "sway/scripts" replacements) // entries;

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
    };
}
