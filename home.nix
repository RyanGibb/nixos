
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
      size = 48;
  };
  # Fix overly large cursor in some applications
  gtk.gtk3.extraConfig = {
    "gtk-cursor-theme-name" = pkgs.lib.mkForce "";
    "gtk-cursor-theme-size" = pkgs.lib.mkForce "";
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
    XDG_CURRENT_DESKTOP = "sway";
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

  xdg = {
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
        set modeindicator false
      '';
      "gammastep/config.ini".text = ''
        [manual]
        lat=52.17
        lon=0.13
      '';
      "../.zprofile".text = ''
        # Autostart sway at login on TTY 1
        if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
        	source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
        	exec sway &> $HOME/.sway_log
        fi
      '';
      "../.xkb/symbols/gb_alt_gr_remapped_to_super".source = ./dotfiles/gb_alt_gr_remapped_to_super.xkb;
      "sway".source = ./dotfiles/sway;
      "waybar".source = ./dotfiles/waybar;
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "thunar.desktop" "code-oss.desktop" ];
        "text/html" = [ "firefox.desktop" "codium.desktop" "neovim.desktop" ];
        "text/plain" = [ "neovim.desktop" "codium.desktop" ];
        "text/markdown" = [ "neovim.desktop" "codium.desktop" ];
        "application/pdf" = "org.gnome.Evince.desktop";
        "image/jpg" = [ "feh.desktop" "gimp.desktop" ];
        "image/png" = [ "feh.desktop" "gimp.desktop" ];
        "image/svg" = [ "feh.desktop" "gimp.desktop" ];
        "application/xbittorrent" = "transmission.desktop";
        "x-scheme-handler/magnet" = "transmission.desktop";
        "x-scheme-handler" = "firefox.desktop";
        "application/lrf" = "calibre-lrfviewer.desktop";
      };
    };
    userDirs = {
      enable = true;
      download    = "$HOME/downloads";
      documents   = "$HOME/documents";
      pictures    = "$HOME/pictures";
      videos      = "$HOME/pictures";
      music       = "$HOME";
      desktop     = "$HOME";
      templates   = "$HOME";
      publicShare = "$HOME";
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      james-yu.latex-workshop
      streetsidesoftware.code-spell-checker
      ms-vscode-remote.remote-ssh
      ocamllabs.ocaml-platform
      valentjn.vscode-ltex
    ];
    userSettings = import ./dotfiles/vscode.nix;
  };
  # https://github.com/nix-community/home-manager/issues/1800#issuecomment-853589961
  home.activation.boforeCheckLinkTargets = {
    after = [];
    before = [ "checkLinkTargets" ];
    data = ''
      userDir=/home/ryan/.config/VSCodium/User
      rm -rf $userDir/settings.json
    '';
  };
  home.activation.afterWriteBoundary = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      userDir=/home/ryan/.config/VSCodium/User
      rm -rf $userDir/settings.json
      cat \
        ${(pkgs.formats.json {}).generate "vscode-user-settings"
          (import ./dotfiles/vscode.nix)} \
        > $userDir/settings.json
    '';
  };

  programs.go.goPath = "~/.go";
}
