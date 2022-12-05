{ pkgs, config, lib, ... }:

let cfg = config.personal.gui; in
{
  options.personal.gui.sway = lib.mkEnableOption "sway";

  config = lib.mkIf cfg.sway {
    home-manager.users.${config.custom.username} = import ../home/sway.nix;

    programs.sway =
    let
      desktopEntries = [
        (pkgs.makeDesktopItem {
          name = "nvim";
          desktopName = "Neovim";
          genericName = "Text Editor";
          exec = "alacritty -e nvim %F";
          terminal = false;
          categories = [ "Application" "Utility" "TextEditor" ];
          icon = "nvim";
          mimeTypes = [ "text/english" "text/plain" ];
        })
        (pkgs.makeDesktopItem {
          name = "obsidian-wayland";
          desktopName = "Obsidian (wayland)";
          exec = "obsidian --ozone-platform=wayland";
          terminal = false;
          categories = [ "Office" ];
          comment = "Knowledge base";
          icon = "obsidian";
          type = "Application";
        })
        (pkgs.makeDesktopItem {
          name = "codium-wayland";
          desktopName = "VSCodium (wayland)";
          genericName = "Text Editor";
          exec = "codium --ozone-platform=wayland %F";
          icon = "code";
          mimeTypes = [ "text/plain" "inode/directory" ];
          terminal = false;
        })
        (pkgs.makeDesktopItem {
          name = "chromium-wayland";
          desktopName = "Chromium (wayland)";
          exec = "chromium --ozone-platform-hint=auto";
          icon = "chromium";
        })
        (pkgs.makeDesktopItem {
          name = "signal-desktop-wayland";
          desktopName = "Signal (wayland)";
          exec = "signal-desktop --ozone-platform=wayland";
          terminal = false;
          type = "Application";
          icon = "signal-desktop";
          comment = "Private messaging from your desktop";
          mimeTypes = [ "x-scheme-handler/sgnl" "x-scheme-handler/signalcaptcha" ];
          categories = [ "Network" "InstantMessaging" "Chat" ];
        })
      ];
    in
    {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = with pkgs; [
        jq
        swaylock
        swayidle
        wl-clipboard
        clipman
        wtype
        gammastep
        waybar
        alacritty
        wofi
        wofi-emoji
        wdisplays
        wf-recorder
        grim
        slurp
        swappy
        mako
        kanshi
        input-remapper
      ] ++ desktopEntries;
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      gtkUsePortal = false;
    };
  };
}
