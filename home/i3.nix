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
    wm = "i3";
    wmmsg = "i3-msg";
    rofi = "rofi";
    app_id = "class";
    bar_extra = "";
    locked = "";
    polkit_gnome = "${pkgs.polkit_gnome}";
    locker = "xsecurelock";
    enable_output = "xrandr --output $laptop_output --auto";
    disable_output = "xrandr --output $laptop_output --off";
    drun = "rofi -i -modi drun -show drun";
    dmenu = "rofi -i -dmenu -p";
    displays = "arandr";
    bar = "i3bar";
    notification_deamon = "dunst";
    i3_workspace_history = "${i3-workspace-history}";
    i3_workspace_history_args = "";
  };
  util = import ./util.nix { inherit pkgs lib; };
  cfg = config.custom.gui.i3;
in
{
  options.custom.gui.i3.enable = lib.mkEnableOption "i3";

  config = lib.mkIf cfg.enable {
    # TODO
    # idling

    home.packages = with pkgs; [ i3-workspace-history ];

    home.pointerCursor.x11.enable = true;

    home.file = {
      ".xinitrc".text = ''
        export XDG_SESSION_TYPE=x11
        export GDK_BACKEND=x11
        export DESKTOP_SESSION=plasma
        export TMUX_TMPDIR=$XDG_RUNTIME_DIR/x-tmux
        eval `dbus-launch`
        export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID DBUS_SESSION_BUS_WINDOWID
        exec i3
      '';
      ".zprofile".text = ''
        # Autostart at login on TTY 2
        if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 2 ]; then
          source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
          exec startx
        fi
      '';
    };

    xdg.configFile =
      let
        entries = {
          "dunst/dunstrc".source = ./dunst;
          "i3/config".text =
            let
              wmFilenames = util.listFilesInDir ./wm/config.d;
            in
            let
              i3Filenames = util.listFilesInDir ./wm/i3;
            in
            (util.concatFilesReplace ([ ./wm/config ] ++ wmFilenames ++ i3Filenames) replacements);
          "rofi/config.rasi".source = ./rofi.rasi;
        };
      in
      (util.inDirReplace ./wm/scripts "i3/scripts" replacements) // entries;

    services.redshift = {
      enable = true;
      provider = "geoclue2";
    };

    services.picom.enable = true;
  };
}
