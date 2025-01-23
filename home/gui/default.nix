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
    inputs.timewall.homeManagerModules.default
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
        WALLPAPER =
          let
            wallpaper = ./wallpaper.jpg;
          in
          pkgs.runCommand (builtins.baseNameOf wallpaper) { } "cp ${wallpaper} $out";
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
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          auto-tab-discard
          bitwarden
          multi-account-containers
          news-feed-eradicator
          istilldontcareaboutcookies
          leechblock-ng
          # search-by-image
          simple-translate
          tree-style-tab
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

    services.timewall = {
      enable = true;
      config = {
        geoclue.timeout = 300000;
        setter = {
          command = [
            "${pkgs.swaybg}/bin/swaybg"
            "-i"
            "%f"
            "-c"
            "282828"
            "-m"
            "fill"
          ];
          overlap = 1000;
        };
      };
    };
  };
}
