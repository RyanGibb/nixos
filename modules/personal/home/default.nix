{ pkgs, config, ... }:

{
  gtk = {
    enable = true;
    font = {
      name = "Noto Sans 11";
      package = pkgs.noto-fonts;
    };
    iconTheme = {
      package = pkgs.gruvbox-dark-icons-gtk;
      name = "gruvbox-dark";
    };
    theme = {
      package = pkgs.gruvbox-dark-gtk;
      name = "gruvbox-dark";
    };
  };

  # evince workaround
  home.sessionVariables.GTK_THEME = "gruvbox-dark";

  home.sessionVariables.WALLPAPER = ./wallpaper.jpg;

  home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
      size = 32;
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

      # sync toolbar
      "services.sync.prefs.sync.browser.uiCustomization.state" = true;

      "extensions.pocket.enabled" = false;
    };
    userChrome = ''
      #webrtcIndicator {
        display: none;
      }

      /* Move find bar to top */
      .browserContainer > findbar {
        -moz-box-ordinal-group: 0;
      }

      #TabsToolbar
      {
          visibility: collapse;
      }
    '';
  in
  {
    enable = true;
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
    package = (pkgs.firefox.override {
      cfg = {
        enableTridactylNative = true;
      };
    });
  };

  home.file = {
    ".xkb/symbols/gb_alt_gr_remapped_to_super".source = ./gb_alt_gr_remapped_to_super.xkb;
    ".config/gtk-3.0/bookmarks" = {
      force = true;
      text = ''
        file:///${config.home.homeDirectory}/archive
        file:///${config.home.homeDirectory}/downloads
        file:///${config.home.homeDirectory}/capture
        file:///${config.home.homeDirectory}/projects
      '';
    };
    ".config/mimeapps.list" = {
      force = true;
      source = ./mimeapps.list;
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
      "Thunar/uca.xml".source = ./thunar.xml;
      "fontconfig/fonts.conf".source = ./fonts.conf;
      "alacritty.yml".source = ./alacritty.yml;
      "Element/config.json".source = ./element.json;
      "swappy/config".text = ''
        [Default]
        save_dir=~/capture/capture/
        save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
      '';
      "tridactyl/tridactylrc".source = ./tridactylrc;
    };
    userDirs = {
      enable = true;
      createDirectories = true;
      download    = "$HOME/downloads";
      pictures    = "$HOME/capture";
      videos      = "$HOME/videos";
      music       = "$HOME/";
      # https://bugzilla.mozilla.org/show_bug.cgi?id=1082717
      documents   = "$HOME/";
      desktop     = "$HOME/";
      templates   = "$HOME/";
      publicShare = "$HOME/";
    };
  };
  
  # https://github.com/nix-community/home-manager/issues/1439#issuecomment-1106208294
  home.activation = {
    linkDesktopApplications = {
      after = [ "writeBoundary" "createXdgUserDirectories" ];
      before = [ ];
      data = ''
        rm -rf ${config.xdg.dataHome}/"applications/home-manager"
        mkdir -p ${config.xdg.dataHome}/"applications/home-manager"
        cp -Lr ${config.home.homeDirectory}/.nix-profile/share/applications/* ${config.xdg.dataHome}/"applications/home-manager/"
      '';
    };
  };

  programs.go.goPath = "~/.go";

  home.stateVersion = "22.05";
}

