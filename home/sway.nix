{
  pkgs,
  config,
  lib,
  ...
}@inputs:

let
  i3-workspace-history =
    inputs.i3-workspace-history.packages.${pkgs.stdenv.hostPlatform.system}.default;
  replacements = {
    wm = "sway";
    wmmsg = "swaymsg";
    rofi = "wofi";
    app_id = "app_id";
    bar_extra = ''
      icon_theme Papirus
    '';
    locked = "--locked";
    polkit_gnome = "${pkgs.polkit_gnome}";
    locker = "swaylock -f -i $WALLPAPER";
    enable_output = "swaymsg output $laptop_output enable";
    disable_output = "swaymsg output $laptop_output disable";
    drun = "wofi -i --show drun --allow-images -a";
    dmenu = "wofi -d -i -p";
    displays = "wdisplays";
    bar = "swaybar";
    notification_deamon = "dunst";
    i3_workspace_history = "${i3-workspace-history}";
    i3_workspace_history_args = "-sway";
  };
  util = import ./util.nix { inherit pkgs lib; };
  cfg = config.custom.gui.sway;
in
{
  options.custom.gui.sway.enable = lib.mkEnableOption "sway";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      i3-workspace-history
      # https://todo.sr.ht/~scoopta/wofi/73
      (stdenv.mkDerivation {
        name = "xterm-compat";
        buildInputs = [ pkgs.bash ];
        dontUnpack = true;
        installPhase = ''
                    mkdir -p $out/bin
                    cat > $out/bin/xterm <<EOF
          #!/usr/bin/env bash

          exec \$TERMINAL "\$@"
          EOF
                    chmod +x $out/bin/xterm
        '';
      })
    ];

    home.file.".zprofile".text = ''
      # Autostart sway at login on TTY 1
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 1 ]; then
        source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
        export QT_QPA_PLATFORM="wayland"
        export SDL_VIDEODRIVER="wayland"
        export MOZ_ENABLE_WAYLAND=1
        export MOZ_DBUS_REMOTE=1
        export QT_STYLE_OVERRIDE="Fusion"
        export WLR_NO_HARDWARE_CURSORS=1
        export NIXOS_OZONE_WL=1

        # for intellij
        export _JAVA_AWT_WM_NONREPARENTING=1

        # for screensharing
        export XDG_SESSION_TYPE="wayland"
        export XDG_CURRENT_DESKTOP="sway"

        exec sway -d
      fi
    '';

    xdg.configFile =
      let
        entries = {
          "fusuma/config.yml".source = ./fusuma.yml;
          "kanshi/config".source = ./kanshi;
          "dunst/dunstrc".source = ./dunst;
          "swaylock/config".source = ./swaylock;
          "wofi/style.css".source = ./wofi.css;
          "swappy/config".text = ''
            [Default]
            save_dir=$XDG_PICTURES_DIR/capture/
            save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
          '';
          "sway/config".text =
            let
              wmFilenames = util.listFilesInDir ./wm/config.d;
            in
            let
              swayFilenames = util.listFilesInDir ./wm/sway;
            in
            (util.concatFilesReplace ([ ./wm/config ] ++ wmFilenames ++ swayFilenames) replacements);
        };
      in
      (util.inDirReplace ./wm/scripts "sway/scripts" replacements) // entries;

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      temperature.day = 6500;
    };
    systemd.user.services.gammastep.Service.ExecStart = lib.mkForce "${pkgs.gammastep}/bin/gammastep -r";
  };
}
