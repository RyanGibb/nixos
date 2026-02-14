{
  pkgs,
  config,
  lib,
  ...
}@inputs:

let
  cfg = config.custom.gui;
in
{
  imports = [
    ./i3.nix
    ./sway.nix
  ];

  options.custom.gui.enable = lib.mkEnableOption "gui";

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      font = {
        name = "Noto Sans 11";
        package = pkgs.noto-fonts;
      };
      iconTheme = {
        package = pkgs.gruvbox-gtk-theme;
        name = "Gruvbox-Dark";
      };
      theme = {
        package = pkgs.gruvbox-gtk-theme;
        name = "Gruvbox-Dark";
      };
      gtk2.force = true;
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style.name = "gtk2";
    };

    home = {
      packages =
        let
          status = pkgs.stdenv.mkDerivation {
            name = "status";

            src = ../status;

            installPhase = ''
              mkdir -p $out
              cp -r * $out
            '';
          };
        in
        [ status ];

      sessionVariables = {
        # evince workaround
        GTK_THEME = "Gruvbox-Dark";
        # Make Qt apps use GTK theme
        QT_QPA_PLATFORMTHEME = "gtk3";
        WALLPAPER_DIR = "$HOME/pictures/wallpapers";
        TERMINAL = "alacritty";
      };
      pointerCursor = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
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

          "extensions.autoDisableScopes" = 0;

          "sidebar.verticalTabs" = true;
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
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          auto-tab-discard
          bitwarden
          multi-account-containers
          news-feed-eradicator
          istilldontcareaboutcookies
          leechblock-ng
          simple-translate
          tridactyl
          ublock-origin
          zotero-connector
        ];
      in
      {
        enable = true;
        profiles.default = {
          inherit settings userChrome extensions;
        };
        profiles.secondary = {
          inherit settings userChrome extensions;
          id = 1;
          isDefault = false;
        };
        package = (
          pkgs.firefox.override {
            nativeMessagingHosts = with pkgs; [ tridactyl-native ];
          }
        );
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
        download = "$HOME/downloads/";
        pictures = "$HOME/pictures/";
        videos = "$HOME/pictures/videos/";
        documents = "$HOME/documents/";
        music = "$HOME/";
        # https://bugzilla.mozilla.org/show_bug.cgi?id=1082717
        desktop = "$HOME/";
        templates = "$HOME/";
        publicShare = "$HOME/";
      };
    };

    i18n = {
      inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = with pkgs; [
            fcitx5-rime
            qt6Packages.fcitx5-chinese-addons
            fcitx5-m17n
          ];
          settings = {
            globalOptions = {
              "Hotkey/TriggerKeys" = {
                "0" = "Alt+Shift+space";
              };
            };
            inputMethod = {
              GroupOrder."0" = "Default";
              "Groups/0" = {
                Name = "Default";
                "Default Layout" = "gb";
                DefaultIM = "pinyin";
              };
              "Groups/0/Items/0".Name = "keyboard-gb";
              "Groups/0/Items/1".Name = "pinyin";
            };
          };
        };
      };
    };
    # https://github.com/nix-community/home-manager/issues/3126
    systemd.user.services.fcitx5-daemon.Service.Environment = [
      "GLFW_IM_MODULE=bus"
      "SDL_IM_MODULE=fcitx"
      "GTK_IM_MODULE=fcitx"
      "QT_IM_MODULE=fcitx"
      "XMODIFIERS=@im=fcitx"
    ];
  };
}
