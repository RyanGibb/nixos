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
  set_wallpaper = ''
    swaymsg "output * bg $WALLPAPER_DIR/default fill #2e3440"
  '';
  locker = "swaylock -f -i ~/pictures/wallpapers/default";
  enable_output  = "swaymsg output $laptop_output enable";
  disable_output = "swaymsg output $laptop_output disable";
  drun = "wofi -i --show drun --allow-images -a";
  run = "wofi -i --show run";
  dmenu = "wofi -d -i -p";
  rofimoji = "wofi-emoji";
  displays = "wdisplays";
  bar = "swaybar";
  notification_deamon = "mako";
  redshift = "gammastep-indicator -r";
}; in
let util = import ./util.nix { pkgs = pkgs; lib = lib; }; in
{
  imports = [
    ./home.nix
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

  xdg.desktopEntries = {
    nvim = {
        name = "Neovim";
        genericName = "Text Editor";
        exec = "alacritty -e nvim %F";
        terminal = false;
        categories = [ "Application" "Utility" "TextEditor" ];
        icon = "nvim";
        mimeType = [ "text/english" "text/plain" ];
    };
    obsidian-wayland = {
        name = "Obsidian (wayland)";
        exec = "obsidian --ozone-platform=wayland";
        terminal = false;
        categories = [ "Office" ];
        comment = "Knowledge base";
        icon = "obsidian";
        type = "Application";
    };
    codium-wayland = {
        name = "VSCodium (wayland)";
        genericName = "Text Editor";
        exec = "codium --ozone-platform=wayland %F";
        icon = "code";
        mimeType = [ "text/plain" "inode/directory" ];
        terminal = false;
    };
    chromium-wayland = {
        name = "Chromium (wayland)";
        exec = "chromium --ozone-platform-hint=auto";
        icon = "chromium";
    };
    signal-desktop-wayland = {
        name = "Signal (wayland)";
        exec = "signal-desktop --ozone-platform=wayland";
        terminal = false;
        type = "Application";
        icon = "signal-desktop";
        comment = "Private messaging from your desktop";
        mimeType = [ "x-scheme-handler/sgnl" "x-scheme-handler/signalcaptcha" ];
        categories = [ "Network" "InstantMessaging" "Chat" ];
    };
  };

  xdg.configFile  =
    let entries = {
      "gammastep/config.ini".text = ''
        [general]
        dawn-time=06:00-07:00
        dusk-time=18:00-19:00
      '';
      "fusuma/config.yml".source = ./dotfiles/fusuma.yml;
      "kanshi/config".source = ./dotfiles/kanshi;
      "mako/config".source = ./dotfiles/mako;
      "swaylock/config".source = ./dotfiles/swaylock;
      "wofi/style.css".source = ./dotfiles/wofi.css;
      "swappy/config".text = ''
        [Default]
        save_dir=$HOME/pictures/capture/
        save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
      '';
      "sway/config".text =
        let wmFilenames = util.listFilesInDir ./dotfiles/wm/config.d; in
        let swayFilenames = util.listFilesInDir ./dotfiles/wm/sway; in
        (util.concatFilesReplace ([ ./dotfiles/wm/config ] ++ wmFilenames ++ swayFilenames) replacements);
      "i3blocks".source = ./dotfiles/i3blocks;
    }; in
    (util.inDirReplace ./dotfiles/wm/scripts "sway/scripts" replacements) // entries;
}
