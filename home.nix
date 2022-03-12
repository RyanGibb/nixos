
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
    gtk3 = {
      bookmarks = [
        "file:///home/ryan/documents"
        "file:///home/ryan/downloads"
        "file:///home/ryan/pictures"
        "file:///home/ryan/projects"
      ];
    };
  };

  xsession.pointerCursor = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
      size = 64;
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
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    XDG_CURRENT_DESKTOP = "sway"; 
  };
  # Sway users might achieve this by adding the following to their Sway config file
  # This ensures all user units started after the command (not those already running) set the variables
  # exec systemctl --user import-environment?

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
      kristofferhagen-nord-theme
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

  programs.zsh = {
    enable = true;
    profileExtra = ''
      # https://github.com/boltgolt/howdy/issues/241
      export OPENCV_LOG_LEVEL=ERROR
      
      # Autostart sway at login on TTY 1
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
      	exec ~/.config/sway/scripts/start.sh
      fi
    '';
  };

  programs.go.goPath = "~/.go";

  home.keyboard = null;
}
