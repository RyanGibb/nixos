{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom.gui.niri;
  scriptDir = "$HOME/.config/niri/scripts";
in
{
  options.custom.gui.niri = {
    enable = lib.mkEnableOption "niri";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wl-clipboard
      clipman
      wtype
      wl-kbptr
      wlrctl
      xwayland-satellite
    ];

    xdg.configFile."niri/scripts/workspace_notifier.sh" = {
      source = ./niri-scripts/workspace_notifier.sh;
      executable = true;
    };

    xdg.configFile."wlr-which-key/system.yaml".source  = ./wlr-which-key/system.yaml;
    xdg.configFile."wlr-which-key/capture.yaml".source = ./wlr-which-key/capture.yaml;
    xdg.configFile."wlr-which-key/control.yaml".source = ./wlr-which-key/control.yaml;
    xdg.configFile."wlr-which-key/idle.yaml".source    = ./wlr-which-key/idle.yaml;

    xdg.configFile."niri/config.kdl".text = ''
      input {
          keyboard {
              xkb {
                  layout "gb"
              }
              numlock
          }
          touchpad {
              tap
              natural-scroll
              dwt
              accel-speed 0.2
              click-method "clickfinger"
              scroll-factor 0.5
          }
          mouse {
              accel-profile "flat"
              accel-speed 0.0
          }
          focus-follows-mouse
          workspace-auto-back-and-forth
      }

      layout {
          gaps 8
          center-focused-column "never"
          preset-column-widths {
              proportion 0.33333
              proportion 0.5
              proportion 0.66667
          }
          default-column-width { proportion 0.5; }
          focus-ring {
              width 2
              active-color "#83a598"
              inactive-color "#3c3836"
          }
          border {
              off
          }
          tab-indicator {
              width 6
              gap 6
              length total-proportion=1.0
              place-within-column
              active-color "#83a598"
              inactive-color "#3c3836"
          }
      }

      environment {
          QT_QPA_PLATFORM "wayland"
          QT_STYLE_OVERRIDE "Fusion"
          SDL_VIDEODRIVER "wayland"
          MOZ_ENABLE_WAYLAND "1"
          MOZ_DBUS_REMOTE "1"
          NIXOS_OZONE_WL "1"
          _JAVA_AWT_WM_NONREPARENTING "1"
          XDG_SESSION_TYPE "wayland"
          XDG_CURRENT_DESKTOP "niri"
          DISPLAY ":0"
      }

      spawn-at-startup "systemctl" "--user" "start" "wayland-session.target"
      spawn-at-startup "xwayland-satellite"
      spawn-at-startup "sh" "-c" "swaybg -i $HOME/.cache/wallpaper -m fill"

      // Pinned workspaces: apps below open on these by name.
      // Position order = number order, so Mod+1..4 still hit them.
      workspace "emacs"
      workspace "term"
      workspace "web"
      workspace "chat"

      prefer-no-csd
      hotkey-overlay { skip-at-startup; }

      recent-windows {
          binds {
              Mod+o       { next-window; }
              Mod+i       { previous-window; }
              Mod+Shift+o { next-window     filter="app-id"; }
              Mod+Shift+i { previous-window filter="app-id"; }
          }
      }

      screenshot-path "~/pictures/capture/screenshot_%Y-%m-%dT%H:%M:%S%z.png"

      binds {
          // NOTE: bindings that shell out to scripts under $HOME/.config/sway/scripts
          // are reused from the sway config. Any script using `swaymsg` will not
          // work until it has a niri (`niri msg`) port. `st` is the sway status
          // notifier script; it works standalone since it only uses dunstify.

          Mod+Shift+Slash { show-hotkey-overlay; }

          // --- Terminals & launchers ---
          Mod+Return       hotkey-overlay-title="Terminal (tmux)"                    { spawn "alacritty" "-e" "tmux"; }
          Mod+Shift+Return hotkey-overlay-title="Terminal (tmux attach)"             { spawn "alacritty" "-e" "tmux" "attach"; }
          Mod+Alt+Return   hotkey-overlay-title="Terminal (no wayland)"              { spawn "sh" "-c" "WAYLAND_DISPLAY= alacritty -e tmux"; }
          Mod+d            hotkey-overlay-title="App launcher (wofi)"                { spawn "wofi" "-i" "--show" "drun" "--allow-images" "-a"; }
          Mod+Escape       hotkey-overlay-title="Status (st)"                        { spawn "st"; }
          Mod+Shift+Escape hotkey-overlay-title="Status (st, full)"                  { spawn "st" "date" "workspace" "mail" "idle" "disk" "temperature" "load_average" "memory" "backlight" "player" "battery"; }
          Mod+b            hotkey-overlay-title="Firefox"                            { spawn "firefox"; }
          Mod+Shift+b      hotkey-overlay-title="Firefox (secondary profile)"        { spawn "firefox" "-P" "secondary"; }
          Mod+Ctrl+b       hotkey-overlay-title="Firefox (private)"                  { spawn "firefox" "-private-window"; }

          // Clipboard (clipman)
          Mod+Shift+v         hotkey-overlay-title="Clipboard picker (clipman)"      { spawn "sh" "-c" "clipman pick -t wofi -T-i"; }
          Mod+Ctrl+v          hotkey-overlay-title="Copy last clipman entry"         { spawn "sh" "-c" "wl-copy \"$(clipman pick -t STDOUT | head -n 1)\""; }
          Mod+Shift+Ctrl+v    hotkey-overlay-title="Type last clipman entry"         { spawn "sh" "-c" "wtype \"$(clipman pick -t STDOUT | head -n 1)\""; }
          Mod+Alt+space       hotkey-overlay-title="Prompt -> clipboard (yad)"       { spawn "sh" "-c" "yad --entry --text input | wl-copy"; }
          Mod+Alt+Shift+space hotkey-overlay-title="Prompt -> type (yad)"            { spawn "sh" "-c" "yad --entry --text input | xargs wtype"; }

          // Emoji
          Mod+apostrophe   hotkey-overlay-title="Emoji picker (rofimoji)"            { spawn "sh" "-c" "rofimoji --selector wofi --selector-args=-i --skin-tone neutral --prompt \"\" -a copy"; }

          // Bluetooth / wifi
          Mod+semicolon       hotkey-overlay-title="Bluetooth connect"               { spawn "sh" "-c" "~/.config/sway/scripts/bluetooth_device.sh"; }
          Mod+Shift+semicolon hotkey-overlay-title="Bluetooth disconnect"            { spawn "sh" "-c" "~/.config/sway/scripts/bluetooth_device.sh disconnect"; }
          Mod+Ctrl+semicolon  hotkey-overlay-title="Wifi picker"                     { spawn "sh" "-c" "~/.config/sway/scripts/wifi.sh"; }

          // Wallpaper
          Mod+Shift+w hotkey-overlay-title="Random wallpaper"                        { spawn "sh" "-c" "~/.config/sway/scripts/set_random_wallpaper.sh"; }
          Mod+Ctrl+w  hotkey-overlay-title="Select wallpaper"                        { spawn "sh" "-c" "~/.config/sway/scripts/set_selected_wallpaper.sh"; }

          // Dunst (notifications)
          Mod+q       hotkey-overlay-title="Dismiss notification"                    { spawn "dunstctl" "close"; }
          Mod+Shift+q hotkey-overlay-title="Notification default action"             { spawn "dunstctl" "action"; }
          Mod+Ctrl+q  hotkey-overlay-title="Notification history"                    { spawn "dunstctl" "history-pop"; }

          // wl-kbptr (keyboard mouse click)
          Mod+p hotkey-overlay-title="Keyboard cursor (wl-kbptr)"                    { spawn "wl-kbptr" "-o" "modes=floating,click" "-o" "mode_floating.source=detect"; }
          // Keyboard-driven cursor movement is available via keyd:
          // Meta+Shift+P enters a mouse layer (see services.keyd in niri module).
          // hjkl move cursor, n/m/,/. scroll, s/d/f click, Escape exits.

          // Dictation
          Mod+Shift+d hotkey-overlay-title="Toggle dictation"                        { spawn "dictation-toggle"; }

          // Rename current workspace (matches sway Mod+t)
          Mod+t hotkey-overlay-title="Rename workspace" { spawn "sh" "-c" "name=$(echo | wofi -d -i -p 'workspace name'); [ -n \"$name\" ] && niri msg action set-workspace-name \"$name\""; }

          // --- Window ops ---
          Mod+Shift+BackSpace { close-window; }
          Mod+f               { fullscreen-window; }
          Mod+Shift+f         hotkey-overlay-title="Send F11 to app" { spawn "wtype" "-k" "F11"; }
          Mod+e               { maximize-column; }
          Mod+w               { toggle-column-tabbed-display; }
          Mod+Shift+space     { toggle-window-floating; }
          Mod+space           { switch-focus-between-floating-and-tiling; }

          // Column focus (h/j/k/l + arrows)
          Mod+h     { focus-column-left; }
          Mod+l     { focus-column-right; }
          Mod+j     { focus-window-or-workspace-down; }
          Mod+k     { focus-window-or-workspace-up; }
          Mod+Left  { focus-column-left; }
          Mod+Right { focus-column-right; }
          Mod+Down  { focus-window-or-workspace-down; }
          Mod+Up    { focus-window-or-workspace-up; }

          // Column move
          Mod+Shift+h     { move-column-left; }
          Mod+Shift+l     { move-column-right; }
          Mod+Shift+j     { move-window-down-or-to-workspace-down; }
          Mod+Shift+k     { move-window-up-or-to-workspace-up; }
          Mod+Shift+Left  { move-column-left; }
          Mod+Shift+Right { move-column-right; }
          Mod+Shift+Down  { move-window-down-or-to-workspace-down; }
          Mod+Shift+Up    { move-window-up-or-to-workspace-up; }

          // Column width / height (coarse then fine)
          Mod+Ctrl+h        { set-column-width "-5%"; }
          Mod+Ctrl+l        { set-column-width "+5%"; }
          Mod+Ctrl+j        { set-window-height "+5%"; }
          Mod+Ctrl+k        { set-window-height "-5%"; }
          Mod+Ctrl+Left     { set-column-width "-5%"; }
          Mod+Ctrl+Right    { set-column-width "+5%"; }
          Mod+Ctrl+Down     { set-window-height "+5%"; }
          Mod+Ctrl+Up       { set-window-height "-5%"; }
          Mod+Ctrl+Shift+h     { set-column-width "-1%"; }
          Mod+Ctrl+Shift+l     { set-column-width "+1%"; }
          Mod+Ctrl+Shift+j     { set-window-height "+1%"; }
          Mod+Ctrl+Shift+k     { set-window-height "-1%"; }
          Mod+Ctrl+Shift+Left  { set-column-width "-1%"; }
          Mod+Ctrl+Shift+Right { set-column-width "+1%"; }
          Mod+Ctrl+Shift+Down  { set-window-height "+1%"; }
          Mod+Ctrl+Shift+Up    { set-window-height "-1%"; }
          Mod+r             { switch-preset-column-width; }

          // Consume/expel windows into/from a column (niri "split" analog)
          Mod+g       { consume-window-into-column; }
          Mod+v       { expel-window-from-column; }
          Mod+Alt+g   { consume-or-expel-window-left; }
          Mod+Alt+v   { consume-or-expel-window-right; }

          // --- Workspaces (1-9, 0=10) ---
          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }
          Mod+0 { focus-workspace 10; }

          Mod+Shift+1 { move-column-to-workspace 1; }
          Mod+Shift+2 { move-column-to-workspace 2; }
          Mod+Shift+3 { move-column-to-workspace 3; }
          Mod+Shift+4 { move-column-to-workspace 4; }
          Mod+Shift+5 { move-column-to-workspace 5; }
          Mod+Shift+6 { move-column-to-workspace 6; }
          Mod+Shift+7 { move-column-to-workspace 7; }
          Mod+Shift+8 { move-column-to-workspace 8; }
          Mod+Shift+9 { move-column-to-workspace 9; }
          Mod+Shift+0 { move-column-to-workspace 10; }

          Mod+grave        { focus-workspace-previous; }
          Mod+period       { focus-workspace-down; }
          Mod+comma        { focus-workspace-up; }
          Mod+Shift+period { move-column-to-workspace-down; }
          Mod+Shift+comma  { move-column-to-workspace-up; }

          Mod+Tab { toggle-overview; }
          // Window switcher: fuzzy pick via wofi, focus by id
          Mod+Shift+Tab { spawn "sh" "-c" "id=$(niri msg --json windows | jq -r '.[] | \"\\(.id)\\t\\(.app_id // \"?\")  \\(.title // \"\")\"' | wofi -d -i -p 'window' | awk '{print $1}'); [ -n \"$id\" ] && niri msg action focus-window --id \"$id\""; }

          // --- Monitors (Mod+Alt+hjkl / arrows / brackets) ---
          Mod+Alt+h        { focus-monitor-left; }
          Mod+Alt+l        { focus-monitor-right; }
          Mod+Alt+j        { focus-monitor-down; }
          Mod+Alt+k        { focus-monitor-up; }
          Mod+Alt+Left     { focus-monitor-left; }
          Mod+Alt+Right    { focus-monitor-right; }
          Mod+Alt+Down     { focus-monitor-down; }
          Mod+Alt+Up       { focus-monitor-up; }
          Mod+bracketleft  { focus-monitor-left; }
          Mod+bracketright { focus-monitor-right; }

          Mod+Alt+Shift+h        { move-column-to-monitor-left; }
          Mod+Alt+Shift+l        { move-column-to-monitor-right; }
          Mod+Alt+Shift+j        { move-column-to-monitor-down; }
          Mod+Alt+Shift+k        { move-column-to-monitor-up; }
          Mod+Alt+Shift+Left     { move-column-to-monitor-left; }
          Mod+Alt+Shift+Right    { move-column-to-monitor-right; }
          Mod+Alt+Shift+Down     { move-column-to-monitor-down; }
          Mod+Alt+Shift+Up       { move-column-to-monitor-up; }
          Mod+Shift+bracketleft  { move-column-to-monitor-left; }
          Mod+Shift+bracketright { move-column-to-monitor-right; }

          Mod+Alt+Ctrl+h        { move-workspace-to-monitor-left; }
          Mod+Alt+Ctrl+l        { move-workspace-to-monitor-right; }
          Mod+Alt+Ctrl+j        { move-workspace-to-monitor-down; }
          Mod+Alt+Ctrl+k        { move-workspace-to-monitor-up; }
          Mod+Alt+Ctrl+Left     { move-workspace-to-monitor-left; }
          Mod+Alt+Ctrl+Right    { move-workspace-to-monitor-right; }
          Mod+Alt+Ctrl+Down     { move-workspace-to-monitor-down; }
          Mod+Alt+Ctrl+Up       { move-workspace-to-monitor-up; }
          Mod+Ctrl+bracketleft  { move-workspace-to-monitor-left; }
          Mod+Ctrl+bracketright { move-workspace-to-monitor-right; }

          // --- Audio ---
          Mod+equal       { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ +10%; st pulse -t 500"; }
          Mod+minus       { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ -10%; st pulse -t 500"; }
          Mod+Shift+equal { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ +1%; st pulse -t 500"; }
          Mod+Shift+minus { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ -1%; st pulse -t 500"; }
          Mod+Ctrl+equal  { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ +5%; st pulse -t 500"; }
          Mod+Ctrl+minus  { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ -5%; st pulse -t 500"; }
          Mod+n           { spawn "sh" "-c" "pactl set-sink-mute   @DEFAULT_SINK@ toggle; st pulse -t 500"; }
          Mod+Shift+n     { spawn "sh" "-c" "pactl set-source-mute @DEFAULT_SOURCE@ toggle; st pulse -t 500"; }
          Mod+y           { spawn "sh" "-c" "~/.config/sway/scripts/cycle_sink.sh && st pulse -t 500"; }
          Mod+Shift+y     { spawn "sh" "-c" "~/.config/sway/scripts/cycle_sink.sh back && st pulse -t 500"; }

          // Media keys
          XF86AudioRaiseVolume         { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ +10%; st pulse -t 500"; }
          XF86AudioLowerVolume         { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ -10%; st pulse -t 500"; }
          Shift+XF86AudioRaiseVolume   { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ +1%; st pulse -t 500"; }
          Shift+XF86AudioLowerVolume   { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ -1%; st pulse -t 500"; }
          Ctrl+XF86AudioRaiseVolume    { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ +5%; st pulse -t 500"; }
          Ctrl+XF86AudioLowerVolume    { spawn "sh" "-c" "pactl set-sink-volume @DEFAULT_SINK@ -5%; st pulse -t 500"; }
          XF86AudioMute                { spawn "sh" "-c" "pactl set-sink-mute   @DEFAULT_SINK@ toggle; st pulse -t 500"; }
          XF86AudioMicMute             { spawn "sh" "-c" "pactl set-source-mute @DEFAULT_SOURCE@ toggle; st pulse -t 500"; }
          XF86AudioPlay                { spawn "sh" "-c" "playerctl play-pause; st player -t 500"; }
          XF86AudioPause               { spawn "sh" "-c" "playerctl play-pause; st player -t 500"; }
          XF86AudioNext                { spawn "sh" "-c" "playerctl next; st player -t 500"; }
          XF86AudioPrev                { spawn "sh" "-c" "playerctl previous; st player -t 500"; }
          XF86AudioStop                { spawn "sh" "-c" "playerctl stop; st player -t 500"; }
          XF86MonBrightnessUp          { spawn "sh" "-c" "brightnessctl set 10%+; st backlight -t 500"; }
          XF86MonBrightnessDown        { spawn "sh" "-c" "brightnessctl set 10%-; st backlight -t 500"; }
          Shift+XF86MonBrightnessUp    { spawn "sh" "-c" "brightnessctl set 1%+; st backlight -t 500"; }
          Shift+XF86MonBrightnessDown  { spawn "sh" "-c" "brightnessctl set 1%-; st backlight -t 500"; }
          Ctrl+XF86MonBrightnessUp     { spawn "sh" "-c" "brightnessctl set 5%+; st backlight -t 500"; }
          Ctrl+XF86MonBrightnessDown   { spawn "sh" "-c" "brightnessctl set 5%-; st backlight -t 500"; }

          // --- Screenshots ---
          Print              { spawn "sh" "-c" "~/.config/sway/scripts/capture_region.sh | wl-copy"; }
          Mod+Print          { spawn "wlr-which-key" "capture"; }
          Ctrl+Print         { screenshot-screen; }
          Alt+Print          { screenshot-window; }
          Mod+Shift+Print    hotkey-overlay-title="Stop screen recording" { spawn "sh" "-c" "pkill -SIGINT wf-recorder; notify-send 'stop recording'"; }

          // --- Session / lock ---
          Mod+x           hotkey-overlay-title="System mode"     { spawn "wlr-which-key" "system"; }
          Mod+c           hotkey-overlay-title="Control mode"    { spawn "wlr-which-key" "control"; }
          Mod+u           hotkey-overlay-title="Idle mode"       { spawn "wlr-which-key" "idle"; }
          Mod+Alt+b       hotkey-overlay-title="Brightness mode" { spawn "wlr-which-key" "control" "--initial-keys" "b"; }
          Mod+Delete      { toggle-keyboard-shortcuts-inhibit; }
      }

      cursor {
          xcursor-theme "Adwaita"
          xcursor-size 32
      }

      window-rule {
          match app-id="firefox" title="^Picture-in-Picture$"
          open-floating true
      }

      // Pin apps to their home workspaces.
      window-rule {
          match app-id="^emacs$"
          open-on-workspace "emacs"
      }
      window-rule {
          match app-id="firefox"
          open-on-workspace "web"
      }
      window-rule {
          match app-id="^nheko$"
          open-on-workspace "chat"
      }
      window-rule {
          match app-id="^element$"
          open-on-workspace "chat"
      }
      window-rule {
          match app-id="^zulip$"
          open-on-workspace "chat"
      }

      // Blur anything translucent
      window-rule {
          geometry-corner-radius 8
          clip-to-geometry true
          background-effect {
              blur true
          }
      }
      layer-rule {
          match namespace="^wofi$"
          match namespace="^notifications$"
          geometry-corner-radius 8
          shadow {
              off
          }
          background-effect {
              blur true
          }
      }
    '';

    services = {
      gammastep = {
        enable = true;
        provider = "geoclue2";
        temperature.day = 6500;
      };
      playerctld.enable = true;
      dunst.enable = true;
      kanshi.enable = true;
      clipman.enable = true;
    };

    systemd.user.services.gammastep.Service.ExecStart =
      lib.mkForce "${pkgs.gammastep}/bin/gammastep -r";

    systemd.user.services.clipman.Service.ExecStart =
      lib.mkForce "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store -P --max-items=1000";

    systemd.user.services.dunst.Service.Type = lib.mkForce "simple";

    systemd.user.services.niri-workspace-notifier = {
      Unit = {
        Description = "Fire st workspace notification on niri workspace change";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "%h/.config/niri/scripts/workspace_notifier.sh";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.configFile = {
      "kanshi/config".source = ./kanshi;
      "dunst/dunstrc".source = ./dunst;
      "swaylock/config".source = ./swaylock;
      "wofi/style.css".source = ./wofi.css;
      "swappy/config".text = ''
        [Default]
        save_dir=$XDG_PICTURES_DIR/capture/
        save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
      '';
    };
  };
}
