{ pkgs, lib, ... }:

let replacements = {
  wm = "sway";
  wmmsg = "swaymsg";
  rofi = "wofi";
  app_id = "app_id";
  bar_extra = ''
    icon_theme Papirus
	  tray_output none
  '';
  preamble = "";
  locked = "--locked";
  polkit_gnome = "${pkgs.polkit_gnome}";
  # TODO wallpaper bindings
  wallpaper = ''
    output * bg ~/pictures/wallpapers/default fill
  '';
  set_wallpaper = ''
    swaymsg "output * bg $WALLPAPER_DIR/default fill"
  '';
  locker = "swaylock";
  enable_output  = "swaymsg output $laptop_output enable";
  disable_output = "swaymsg output $laptop_output disable";
  drun = "wofi -i --show drun --allow-images -a";
  run = "wofi -i --show run";
  dmenu = "wofi -d -i -p";
  rofimoji = "wofi-emoji";
  displays = "wdisplays";
  bar = "swaybar";
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
    WLR_DRM_NO_MODIFIERS = 1;

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
      	source $HOME/.nix-prof${pkgs.polkit_gnome}/le/etc/profile.d/hm-session-vars.sh
      	exec sway &> $HOME/.sway_log
      fi
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
    obsidian = {
        name = "Obsidian (wayland)";
        exec = "obsidian --ozone-platform=wayland";
        terminal = false;
        categories = [ "Office" ];
        comment = "Knowledge base";
        icon = "obsidian";
        type = "Application";
    };
    codium = {
        name = "VSCodium (wayland)";
        genericName = "Text Editor";
        exec = "codium --ozone-platform=wayland %F";
        icon = "code";
        mimeType = [ "text/plain" "inode/directory" ];
        terminal = false;
    };
    chromium = {
        name = "Chromium (wayland)";
        exec = "chromium --ozone-platform-hint=auto";
        icon = "chromium";
    };
    signal-desktop = {
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