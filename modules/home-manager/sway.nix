{ pkgs, ... }:

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
      	source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
      	exec sway &> $HOME/.sway_log
      fi
    '';
  };

  xdg = {
    desktopEntries = {
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
    configFile = {
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
      "sway/config.d".source = ./dotfiles/sway/config.d;
      "sway/scripts".source = ./dotfiles/sway/scripts;
      "sway/config".text = ''
        set $mod Mod4
        set $alt Mod1

        set $term alacritty
        set $browser exec firefox

        set $SCRIPT_DIR $HOME/.config/sway/scripts

        set $VOLUME_DELTA 10
        set $BRIGHTNESS_DELTA 10

        set $inner_gap    0
        set $outer_gap    0
        set $top_gap      0
        set $bottom_gap   0
        set $gutter_ratio 3
        set $gaps_inc     10

        include ~/.config/sway/config.d/*

        exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      '';
    "i3blocks".source = ./dotfiles/i3blocks;
    };
  };
}