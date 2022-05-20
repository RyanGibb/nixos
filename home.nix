
{ pkgs, ... }:

{
  gtk = {
    enable = true;
    font = {
      name = "Noto Sans 11";
      package = pkgs.noto-fonts;
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
    theme = {
      package = pkgs.arc-theme;
      name = "Arc-Dark";
    };
  };

  xsession.pointerCursor = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
      size = 32;
  };

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

  programs.firefox =
  let
    settings = {
      "browser.ctrlTab.recentlyUsedOrder" = false;
      "browser.tabs.warnOnClose" = false;
      "browser.toolbars.bookmarks.visibility" = "never";

      # Only hide UI elements on F11 (i.e. don't go fullscreen, leave that to WM)
      "full-screen-api.ignore-widgets" = true;
      # Right click issue fix
      "ui.context_menus.after_mouseup" = true;

      # Use userChrome.css
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

      "browser.shell.checkDefaultBrowser" = false; 
    };
    userChrome = ''
      #webrtcIndicator {
        display: none;
      }

      /* Move find bar to top */
      .browserContainer > findbar {
        -moz-box-ordinal-group: 0;
      }
    '';
  in
  {
    enable = true;
    package = pkgs.firefox-unwrapped;
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      auto-tab-discard
      facebook-container
      news-feed-eradicator
      lastpass-password-manager
      search-by-image
      simple-tab-groups
      tabliss
      tree-style-tab
      tridactyl
      ublock-origin
      zoom-redirector
    ];
    profiles.default = {
      settings = settings;
      userChrome = userChrome;
    };
    profiles.secondary = {
      id = 1;
      isDefault = false;
      settings = settings;
      userChrome = userChrome;
    };
  };

  home.file = {
    ".zprofile".text = ''
      # Autostart sway at login on TTY 1
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
      	source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
      	exec sway &> $HOME/.sway_log
      fi
    '';
    ".xkb/symbols/gb_alt_gr_remapped_to_super".source = ./dotfiles/gb_alt_gr_remapped_to_super.xkb;
    ".config/gtk-3.0/bookmarks" = {
      force = true;
      text = ''
        file:///home/ryan/archive
        file:///home/ryan/documents
        file:///home/ryan/downloads
        file:///home/ryan/pictures
        file:///home/ryan/projects
      '';
    };
    ".config/mimeapps.list" = {
      force = true;
      source = ./dotfiles/mimeapps.list;
    };
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
    };
    configFile = {
      "Thunar/uca.xml".source = ./dotfiles/thunar.xml;
      "fusuma/config.yml".source = ./dotfiles/fusuma.yml;
      "fontconfig/fonts.conf".source = ./dotfiles/fonts.conf;
      "kanshi/config".source = ./dotfiles/kanshi;
      "mako/config".source = ./dotfiles/mako;
      "swaylock/config".source = ./dotfiles/swaylock;
      "wofi/style.css".source = ./dotfiles/wofi.css;
      "alacritty.yml".source = ./dotfiles/alacritty.yml;
      "swappy/config".text = ''
        [Default]
        save_dir=$HOME/pictures/capture/
        save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
      '';
      "tridactyl/tridactyl".text = ''
        unbind <F1>
        unbind <C-f>
        set modeindicator false
        bind yd tabduplicate
        bind <C-`> buffer #
      '';
      "gammastep/config.ini".text = ''
        [manual]
        lat=52.17
        lon=0.13
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
      "waybar".source = ./dotfiles/waybar;
    };
    userDirs = {
      enable = true;
      createDirectories = true;
      download    = "$HOME/downloads";
      documents   = "$HOME/documents";
      pictures    = "$HOME/pictures";
      videos      = "$HOME/videos";
      music       = "$HOME/";
      # https://bugzilla.mozilla.org/show_bug.cgi?id=1082717
      desktop     = "$HOME/";
      templates   = "$HOME/";
      publicShare = "$HOME/";
    };
  };

  programs.go.goPath = "~/.go";
}
