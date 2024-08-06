{ pkgs, config, lib, ... }:

let cfg = config.custom.gui;
in {
  options.custom.gui.enable = lib.mkEnableOption "gui";

  config = lib.mkIf cfg.enable {
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

    home = {
      sessionVariables = {
        # evince workaround
        GTK_THEME = "gruvbox-dark";
        WALLPAPER = let wallpaper = ./wallpaper.jpg;
        in pkgs.runCommand (builtins.baseNameOf wallpaper) { }
        "cp ${wallpaper} $out";
        TERMINAL = "alacritty";
      };
      pointerCursor = {
        name = "Adwaita";
        package = pkgs.gnome.adwaita-icon-theme;
        size = 32;
      };
      file = {
        ".profile".text = ''
          source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        '';
        ".config/gtk-3.0/bookmarks" = {
          force = true;
          text = ''
            file:///${config.home.homeDirectory}/archive
            file:///${config.home.homeDirectory}/documents
            file:///${config.home.homeDirectory}/downloads
            file:///${config.home.homeDirectory}/pictures
            file:///${config.home.homeDirectory}/videos
            file:///${config.home.homeDirectory}/projects
          '';
        };
        ".config/mimeapps.list" = {
          force = true;
          source = ./mimeapps.list;
        };
      };
    };

    programs.firefox = let
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
    in {
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
        nativeMessagingHosts = with pkgs; [ tridactyl-native ];
      });
    };

    xdg = {
      configFile = {
        "Thunar/uca.xml".source = ./thunar.xml;
        "fontconfig/fonts.conf".source = ./fonts.conf;
        "alacritty.toml".source = ./alacritty.toml;
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
        download = "$HOME/downloads";
        pictures = "$HOME/pictures";
        videos = "$HOME/videos";
        documents = "$HOME/documents/";
        music = "$HOME/";
        # https://bugzilla.mozilla.org/show_bug.cgi?id=1082717
        desktop = "$HOME/";
        templates = "$HOME/";
        publicShare = "$HOME/";
      };
    };
  };
}
