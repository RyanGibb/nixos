{
  pkgs,
  config,
  lib,
  ...
}@inputs:

let
  i3-workspace-history =
    inputs.i3-workspace-history.packages.${pkgs.stdenv.hostPlatform.system}.default;
  util = import ./util.nix { inherit pkgs lib; };
  cfg = config.custom.gui.i3;
  wmCommon = import ./wm-config.nix {
    inherit pkgs lib i3-workspace-history;
  };
  scriptDir = "$HOME/.config/i3/scripts";
  replacements = {
    wm = "i3";
    wmmsg = "i3-msg";
    rofi = "rofi";
    app_id = "class";
    bar_extra = "";
    locked = "";
    polkit_gnome = "${pkgs.polkit_gnome}";
    set_wallpaper = ''feh --bg-fill $HOME/.cache/wallpaper'';
    locker = "xsecurelock";
    enable_output = "xrandr --output $laptop_output --auto";
    disable_output = "xrandr --output $laptop_output --off";
    drun = "rofi -i -modi drun -show drun";
    dmenu = "rofi -i -dmenu -p";
    notification_deamon = "dunst";
    i3_workspace_history = "${i3-workspace-history}/bin/i3-workspace-history";
    i3_workspace_history_args = "";
  };
in
{
  options.custom.gui.i3.enable = lib.mkEnableOption "i3";

  config = lib.mkIf cfg.enable {
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
    };

    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = "Mod4";
        terminal = "alacritty -e tmux";
        menu = "rofi -i -modi drun -show drun";
        bars = [ ];
        fonts = wmCommon.fonts;
        colors = wmCommon.wmColors;
        gaps = wmCommon.gaps;
        window = wmCommon.window // {
          commands = wmCommon.windowCommands.i3;
        };
        floating = wmCommon.floating // {
          criteria = wmCommon.floatingCriteria.i3;
        };
        focus = wmCommon.focus;
        keybindings = lib.mkForce (
          (wmCommon.commonKeybindings scriptDir)
          // (wmCommon.mediaKeybindings false)
          # locked=false for i3
          // (wmCommon.i3Keybindings scriptDir)
        );
        modes = wmCommon.commonModes // (wmCommon.i3Modes scriptDir);
        startup = wmCommon.commonStartup ++ (wmCommon.i3Startup scriptDir replacements.set_wallpaper);
      };
    };

    xdg.configFile =
      let
        entries = {
          "dunst/dunstrc".source = ./dunst;
          "rofi/config.rasi".source = ./rofi.rasi;
        };
      in
      (util.inDirReplace ./scripts "i3/scripts" replacements) // entries;

    services.redshift = {
      enable = true;
      provider = "geoclue2";
    };

    services.picom.enable = true;
  };
}
