{
  pkgs,
  lib,
  i3-workspace-history,
  ...
}:

let
  # Gruvbox
  colors = {
    white = "#edbbb2";
    bg = "#282828";
    red = "#cc241d";
    green = "#98971a";
    yellow = "#d79921";
    blue = "#458588";
    purple = "#b16286";
    aqua = "#689d68";
    gray = "#a89984";
    darkgray = "#1d2021";
    softgray = "#32302f";
    lightgray = "#bdae93";
  };
in
{
  inherit colors;

  wmColors = {
    focused = {
      border = colors.lightgray;
      background = colors.lightgray;
      text = colors.darkgray;
      indicator = colors.purple;
      childBorder = colors.lightgray;
    };
    focusedInactive = {
      border = colors.softgray;
      background = colors.softgray;
      text = colors.lightgray;
      indicator = colors.purple;
      childBorder = colors.softgray;
    };
    unfocused = {
      border = colors.softgray;
      background = colors.darkgray;
      text = colors.lightgray;
      indicator = colors.purple;
      childBorder = colors.softgray;
    };
    urgent = {
      border = colors.red;
      background = colors.red;
      text = colors.white;
      indicator = colors.purple;
      childBorder = colors.red;
    };
    placeholder = {
      border = "#000000";
      background = colors.lightgray;
      text = colors.bg;
      indicator = "#000000";
      childBorder = colors.lightgray;
    };
    background = "#ffffff";
  };

  fonts = {
    names = [ "Noto Sans Mono" ];
    size = 14.0;
  };

  gaps = {
    smartGaps = true;
    smartBorders = "on";
  };

  window = {
    border = 4;
    titlebar = false;
  };

  floating = {
    border = 4;
    titlebar = false;
    modifier = "Mod4";
  };

  focus = {
    followMouse = false;
    newWindow = "smart";
  };

  floatingCriteria = {
    sway = [
      { app_id = "yad"; }
      { app_id = "zoom"; }
      { app_id = "zoom"; title = "Choose ONE of the audio conference options"; }
      { app_id = "zoom"; title = "zoom"; }
      { app_id = "copyq"; }
    ];
    i3 = [
      { class = "yad"; }
      { class = "zoom"; }
      { class = "zoom"; title = "Choose ONE of the audio conference options"; }
      { class = "zoom"; title = "zoom"; }
      { class = "copyq"; }
    ];
  };

  windowCommands = {
    sway = [
      {
        criteria = { app_id = "zoom"; title = "Zoom Meeting"; };
        command = "floating disable";
      }
      {
        criteria = { app_id = "zoom"; title = "Zoom - Free Account"; };
        command = "floating disable";
      }
      {
        criteria = { app_id = "copyq"; };
        command = "floating enable, sticky enable, resize set height 600px width 550px, move position cursor, move down 330";
      }
      {
        criteria = { shell = ".*"; };
        command = "title_format \"%title :: %shell\"";
      }
      {
        criteria = { app_id = "Kodi"; };
        command = "1";
      }
    ];
    i3 = [
      {
        criteria = { class = "zoom"; title = "Zoom Meeting"; };
        command = "floating disable";
      }
      {
        criteria = { class = "zoom"; title = "Zoom - Free Account"; };
        command = "floating disable";
      }
      {
        criteria = { class = "copyq"; };
        command = "floating enable, sticky enable, resize set height 600px width 550px, move position cursor, move down 330";
      }
    ];
  };

  mediaKeybindings = locked:
    let prefix = if locked then "--locked " else "";
    in {
      "${prefix}XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +10%; exec st pulse -t 500";
      "${prefix}XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -10%; exec st pulse -t 500";
      "${prefix}Shift+XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +1%; exec st pulse -t 500";
      "${prefix}Shift+XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -1%; exec st pulse -t 500";
      "${prefix}Control+XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%; exec st pulse -t 500";
      "${prefix}Control+XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%; exec st pulse -t 500";
      "${prefix}XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle; exec st pulse -t 500";
      "${prefix}XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle; exec st pulse -t 500";

      "${prefix}XF86AudioPlay" = "exec playerctl play-pause && st player";
      "${prefix}XF86AudioPause" = "exec playerctl play-pause && st player";
      "${prefix}XF86AudioPrev" = "exec playerctl previous";
      "${prefix}XF86AudioNext" = "exec playerctl next";
      "${prefix}XF86AudioStop" = "exec playerctl stop && st player";

      "${prefix}XF86MonBrightnessUp" = "exec brightnessctl set 10%+; exec st backlight -t 500";
      "${prefix}XF86MonBrightnessDown" = "exec brightnessctl set 10%-; exec st backlight -t 500";
      "${prefix}Shift+XF86MonBrightnessUp" = "exec brightnessctl set 1%+; exec st backlight -t 500";
      "${prefix}Shift+XF86MonBrightnessDown" = "exec brightnessctl set 1%-; exec st backlight -t 500";
      "${prefix}Control+XF86MonBrightnessUp" = "exec brightnessctl set 5%+; exec st backlight -t 500";
      "${prefix}Control+XF86MonBrightnessDown" = "exec brightnessctl set 5%-; exec st backlight -t 500";
      
      "${prefix}Mod4+equal" = "exec pactl set-sink-volume @DEFAULT_SINK@ +10%; exec st pulse -t 500";
      "${prefix}Mod4+minus" = "exec pactl set-sink-volume @DEFAULT_SINK@ -10%; exec st pulse -t 500";
      "${prefix}Mod4+Shift+equal" = "exec pactl set-sink-volume @DEFAULT_SINK@ +1%; exec st pulse -t 500";
      "${prefix}Mod4+Shift+minus" = "exec pactl set-sink-volume @DEFAULT_SINK@ -1%; exec st pulse -t 500";
      "${prefix}Mod4+Control+equal" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%; exec st pulse -t 500";
      "${prefix}Mod4+Control+minus" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%; exec st pulse -t 500";
    };

  commonKeybindings = scriptDir: {
    "Mod4+Return" = "exec alacritty -e tmux";
    "Mod4+Shift+Return" = "exec alacritty -e tmux attach";
    "Mod4+Shift+Backspace" = "kill";
    "Mod4+g" = "split h";
    "Mod4+v" = "split v";
    "Mod4+f" = "fullscreen toggle; exec st fullscreen -t 500";
    "Mod4+Shift+f" = "exec wtype -k F11";
    "Mod4+Control+f" = "fullscreen toggle global; exec st fullscreen -t 500";

    "Mod4+s" = "layout stacking";
    "Mod4+w" = "layout tabbed";
    "Mod4+e" = "layout toggle split";
    "Mod4+Mod1+g" = "split h; layout tabbed";
    "Mod4+Mod1+v" = "split v; layout stacking";

    "Mod4+Shift+space" = "floating toggle";
    "Mod4+space" = "focus mode_toggle";
    "Mod4+Control+space" = "sticky toggle";

    "Mod4+a" = "focus parent";
    "Mod4+z" = "focus child";
    "Mod4+Shift+a" = "exec ${scriptDir}/focus_root.sh";
    "Mod4+Shift+z" = "exec ${scriptDir}/focus_leaf.sh";

    "Mod4+1" = "workspace number 1; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+2" = "workspace number 2; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+3" = "workspace number 3; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+4" = "workspace number 4; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+5" = "workspace number 5; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+6" = "workspace number 6; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+7" = "workspace number 7; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+8" = "workspace number 8; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+9" = "workspace number 9; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+0" = "workspace number 10; exec dunstify -C `cat ~/.cache/st_id`";

    "Mod4+Shift+1" = "move container to workspace number 1";
    "Mod4+Shift+2" = "move container to workspace number 2";
    "Mod4+Shift+3" = "move container to workspace number 3";
    "Mod4+Shift+4" = "move container to workspace number 4";
    "Mod4+Shift+5" = "move container to workspace number 5";
    "Mod4+Shift+6" = "move container to workspace number 6";
    "Mod4+Shift+7" = "move container to workspace number 7";
    "Mod4+Shift+8" = "move container to workspace number 8";
    "Mod4+Shift+9" = "move container to workspace number 9";
    "Mod4+Shift+0" = "move container to workspace number 10";
    "Mod4+Control+1" = "workspace number 11; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+2" = "workspace number 12; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+3" = "workspace number 13; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+4" = "workspace number 14; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+5" = "workspace number 15; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+6" = "workspace number 16; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+7" = "workspace number 17; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+8" = "workspace number 18; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+9" = "workspace number 19; exec dunstify -C `cat ~/.cache/st_id`";
    "Mod4+Control+0" = "workspace number 20; exec dunstify -C `cat ~/.cache/st_id`";

    "Mod4+Mod1+1" = "exec swaymsg rename workspace to 1";
    "Mod4+Mod1+2" = "exec swaymsg rename workspace to 2";
    "Mod4+Mod1+3" = "exec swaymsg rename workspace to 3";
    "Mod4+Mod1+4" = "exec swaymsg rename workspace to 4";
    "Mod4+Mod1+5" = "exec swaymsg rename workspace to 5";
    "Mod4+Mod1+6" = "exec swaymsg rename workspace to 6";
    "Mod4+Mod1+7" = "exec swaymsg rename workspace to 7";
    "Mod4+Mod1+8" = "exec swaymsg rename workspace to 8";
    "Mod4+Mod1+9" = "exec swaymsg rename workspace to 9";
    "Mod4+Mod1+0" = "exec swaymsg rename workspace to 10";
    "Mod4+Mod1+Control+1" = "exec swaymsg rename workspace to 11";
    "Mod4+Mod1+Control+2" = "exec swaymsg rename workspace to 12";
    "Mod4+Mod1+Control+3" = "exec swaymsg rename workspace to 13";
    "Mod4+Mod1+Control+4" = "exec swaymsg rename workspace to 14";
    "Mod4+Mod1+Control+5" = "exec swaymsg rename workspace to 15";
    "Mod4+Mod1+Control+6" = "exec swaymsg rename workspace to 16";
    "Mod4+Mod1+Control+7" = "exec swaymsg rename workspace to 17";
    "Mod4+Mod1+Control+8" = "exec swaymsg rename workspace to 18";
    "Mod4+Mod1+Control+9" = "exec swaymsg rename workspace to 19";
    "Mod4+Mod1+Control+0" = "exec swaymsg rename workspace to 20";

    "Mod4+Shift+Control+1" = "move container to workspace number 11";
    "Mod4+Shift+Control+2" = "move container to workspace number 12";
    "Mod4+Shift+Control+3" = "move container to workspace number 13";
    "Mod4+Shift+Control+4" = "move container to workspace number 14";
    "Mod4+Shift+Control+5" = "move container to workspace number 15";
    "Mod4+Shift+Control+6" = "move container to workspace number 16";
    "Mod4+Shift+Control+7" = "move container to workspace number 17";
    "Mod4+Shift+Control+8" = "move container to workspace number 18";
    "Mod4+Shift+Control+9" = "move container to workspace number 19";
    "Mod4+Shift+Control+0" = "move container to workspace number 20";

    "Mod4+Shift+grave" = "move container to workspace back_and_forth";

    "Mod4+Shift+numbersign" = "move scratchpad";
    "Mod4+numbersign" = "scratchpad show";

    "Mod4+h" = "focus left";
    "Mod4+j" = "focus down";
    "Mod4+k" = "focus up";
    "Mod4+l" = "focus right";

    "Mod4+Shift+h" = "move left 25px";
    "Mod4+Shift+j" = "move down 25px";
    "Mod4+Shift+k" = "move up 25px";
    "Mod4+Shift+l" = "move right 25px";

    "Mod4+Control+h" = "resize shrink width 25px or 5ppt";
    "Mod4+Control+j" = "resize grow height 25px or 5ppt";
    "Mod4+Control+k" = "resize shrink height 25px or 5ppt";
    "Mod4+Control+l" = "resize grow width 25px or 5ppt";

    "Mod4+Control+Shift+h" = "resize shrink width 1px";
    "Mod4+Control+Shift+j" = "resize grow height 1px";
    "Mod4+Control+Shift+k" = "resize shrink height 1px";
    "Mod4+Control+Shift+l" = "resize grow width 1px";

    "Mod4+Left" = "focus left";
    "Mod4+Down" = "focus down";
    "Mod4+Up" = "focus up";
    "Mod4+Right" = "focus right";

    "Mod4+Shift+Left" = "move left 25px";
    "Mod4+Shift+Down" = "move down 25px";
    "Mod4+Shift+Up" = "move up 25px";
    "Mod4+Shift+Right" = "move right 25px";

    "Mod4+Control+Left" = "resize shrink width 25px or 5ppt";
    "Mod4+Control+Down" = "resize grow height 25px or 5ppt";
    "Mod4+Control+Up" = "resize shrink height 25px or 5ppt";
    "Mod4+Control+Right" = "resize grow width 25px or 5ppt";

    "Mod4+Control+Shift+Left" = "resize shrink width 1px";
    "Mod4+Control+Shift+Down" = "resize grow height 1px";
    "Mod4+Control+Shift+Up" = "resize shrink height 1px";
    "Mod4+Control+Shift+Right" = "resize grow width 1px";

    "Mod4+Mod1+h" = "focus output left; exec st workspace -t 500";
    "Mod4+Mod1+j" = "focus output down; exec st workspace -t 500";
    "Mod4+Mod1+k" = "focus output up; exec st workspace -t 500";
    "Mod4+Mod1+l" = "focus output right; exec st workspace -t 500";

    "Mod4+Mod1+Left" = "focus output left; exec st workspace -t 500";
    "Mod4+Mod1+Down" = "focus output down; exec st workspace -t 500";
    "Mod4+Mod1+Up" = "focus output up; exec st workspace -t 500";
    "Mod4+Mod1+Right" = "focus output right; exec st workspace -t 500";

    "Mod4+Mod1+Shift+h" = "move container to output left";
    "Mod4+Mod1+Shift+j" = "move container to output down";
    "Mod4+Mod1+Shift+k" = "move container to output up";
    "Mod4+Mod1+Shift+l" = "move container to output right";

    "Mod4+Mod1+Shift+Left" = "move container to output left; exec st workspace -t 500";
    "Mod4+Mod1+Shift+Down" = "move container to output down; exec st workspace -t 500";
    "Mod4+Mod1+Shift+Up" = "move container to output up; exec st workspace -t 500";
    "Mod4+Mod1+Shift+Right" = "move container to output right; exec st workspace -t 500";

    "Mod4+Mod1+Control+h" = "move workspace to output left";
    "Mod4+Mod1+Control+j" = "move workspace to output down";
    "Mod4+Mod1+Control+k" = "move workspace to output up";
    "Mod4+Mod1+Control+l" = "move workspace to output right";

    "Mod4+Mod1+Control+Left" = "move workspace to output left; exec st workspace -t 500";
    "Mod4+Mod1+Control+Down" = "move workspace to output down; exec st workspace -t 500";
    "Mod4+Mod1+Control+Up" = "move workspace to output up; exec st workspace -t 500";
    "Mod4+Mod1+Control+Right" = "move workspace to output right; exec st workspace -t 500";

    "Mod4+bracketleft" = "focus output left; exec dunstify -C `cat ~/.cache/st_id` && st workspace -t 500";
    "Mod4+bracketright" = "focus output right; exec dunstify -C `cat ~/.cache/st_id` && st workspace -t 500";
    "Mod4+Shift+bracketleft" = "move container to output left; exec dunstify -C `cat ~/.cache/st_id` && st workspace -t 500";
    "Mod4+Shift+bracketright" = "move container to output right; exec dunstify -C `cat ~/.cache/st_id` && st workspace -t 500";
    "Mod4+Control+bracketleft" = "move workspace to output left; exec dunstify -C `cat ~/.cache/st_id` && st workspace -t 500";
    "Mod4+Control+bracketright" = "move workspace to output right; exec dunstify -C `cat ~/.cache/st_id` && st workspace -t 500";

    "Mod4+b" = "exec firefox";
    "Mod4+Shift+b" = "exec firefox -P secondary";
    "Mod4+Control+b" = "exec firefox -private-window";

    "Mod4+Escape" = "exec st";
    "Mod4+Shift+Escape" = "exec st date workspace mail idle disk temperature load_average memory backlight player battery";
    "Mod4+grave" = "workspace back_and_forth; exec dunstify -C `cat ~/.cache/st_id` && st workspace -t 500";
    "Mod4+period" = "workspace next_on_output; exec st workspace -t 500";
    "Mod4+comma" = "workspace prev_on_output; exec st workspace -t 500";

    "Mod4+Shift+period" = "move container to workspace next_on_output";
    "Mod4+Shift+comma" = "move container to workspace prev_on_output";

    "Mod4+m" = "exec ${scriptDir}/ws_switch.sh ${scriptDir}/get_free_ws_num.sh";
    "Mod4+Shift+m" = "exec ${scriptDir}/ws_mv.sh ${scriptDir}/get_free_ws_num.sh";
    "Mod4+Control+m" = "exec ${scriptDir}/ws_switch_mv.sh ${scriptDir}/get_free_ws_num.sh";

    "Mod4+backslash" = "exec ${scriptDir}/ws_switch.sh ${scriptDir}/select_ws.sh";
    "Mod4+Shift+backslash" = "exec ${scriptDir}/ws_mv.sh ${scriptDir}/select_ws.sh";
    "Mod4+Control+backslash" = "exec ${scriptDir}/ws_switch_mv.sh ${scriptDir}/select_ws.sh";

    "Mod4+t" = "exec ${scriptDir}/title_ws.sh ${scriptDir}/get_ws_title.sh ${scriptDir}/get_cur_ws_name.sh";

    "Mod4+i" = "exec ${i3-workspace-history}/bin/i3-workspace-history -mode=forward -sway; exec st workspace -t 500";
    "Mod4+o" = "exec ${i3-workspace-history}/bin/i3-workspace-history -mode=back -sway; exec st workspace -t 500";

    "Mod4+Tab" = "exec ${scriptDir}/window_switcher.sh";
    "Mod4+Shift+Tab" = "exec ${scriptDir}/window_switcher_scratch.sh";

    "Mod4+equal" = "exec pactl set-sink-volume @DEFAULT_SINK@ +10%; exec st pulse -t 500";
    "Mod4+minus" = "exec pactl set-sink-volume @DEFAULT_SINK@ -10%; exec st pulse -t 500";
    "Mod4+Shift+equal" = "exec pactl set-sink-volume @DEFAULT_SINK@ +1%; exec st pulse -t 500";
    "Mod4+Shift+minus" = "exec pactl set-sink-volume @DEFAULT_SINK@ -1%; exec st pulse -t 500";
    "Mod4+Control+equal" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%; exec st pulse -t 500";
    "Mod4+Control+minus" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%; exec st pulse -t 500";

    "Mod4+y" = "exec ${scriptDir}/cycle_sink.sh && st pulse -t 500";
    "Mod4+Shift+y" = "exec ${scriptDir}/cycle_sink.sh back && st pulse -t 500";
    "Mod4+n" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle; exec st pulse -t 500";
    "Mod4+Shift+n" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle; exec st pulse -t 500";

    "Mod4+apostrophe" = "exec rofimoji --selector wofi --selector-args=-i --skin-tone neutral --prompt \"\" -a copy";
    "Mod4+semicolon" = "exec ${scriptDir}/bluetooth_device.sh";
    "Mod4+Shift+semicolon" = "exec ${scriptDir}/bluetooth_device.sh disconnect";
    "Mod4+Control+semicolon" = "exec ${scriptDir}/wifi.sh";

    "button2" = "kill";

    "Mod4+Shift+g" = "mode \"gaps\"; exec notify-send \"Gaps | h/j/k/l/-/+ | 0 1 2 3 4\"";
    "Mod4+x" = "mode \"system\"; exec notify-send \"System | l/e/s/S/h/r/p/u\"";

    "Mod4+Shift+w" = "exec ${scriptDir}/set_random_wallpaper.sh";
    "Mod4+Control+w" = "exec ${scriptDir}/set_selected_wallpaper.sh";
  };

  swayKeybindings = scriptDir: {
    "Mod4+Shift+r" = "exec swaymsg reload; swaymsg \"output * bg $HOME/.cache/wallpaper fill #282828\"";
    "Mod4+d" = "exec wofi -i --show drun --allow-images -a";

    "Mod4+c" = "mode \"control\"; exec notify-send \"Control b/t/d/o\"";
    "Mod4+u" = "mode \"idle\"; exec notify-send \"Idle i/d/l/s/S/L\"";
    "Mod4+Print" = "mode \"capture\"; exec notify-send \"Capture (c)opy/(e)dit/(f)file c/e/f selection C/E/F output (v)ideo\"";
    "Mod4+Shift+Print" = "exec pkill -SIGINT wf-recorder; exec notify-send \"stop recording\"";
    "Mod4+Delete" = "mode \"passthrough\"; exec notify-send \"passthrough on\"";
    "Mod4+p" = "exec wl-kbptr -o modes=floating','click -o mode_floating.source=detect";
    "Mod4+Shift+p" = "mode \"mouse\"; seat seat0 hide_cursor when-typing disable; exec notify-send \"Mouse a/h/j/k/l s/d/f\"";

    "Mod4+Mod1+Return" = "exec WAYLAND_DISPLAY= alacritty -e tmux";
    "Mod4+Mod1+space" = "exec yad --entry --text input | wl-copy";
    "Mod4+Mod1+Shift+space" = "exec yad --entry --text input | xargs wtype";
    "Mod4+Shift+v" = "exec clipman pick -t wofi -T-i";
    "Mod4+Control+v" = "exec wl-copy \"$(clipman pick -t STDOUT | head -n 1)\"";
    "Mod4+Shift+Control+v" = "exec wtype \"$(clipman pick -t STDOUT | head -n 1)\"";
    "Mod4+q" = "exec dunstctl close";
    "Mod4+Shift+q" = "exec dunstctl action";
    "Mod4+Control+q" = "exec dunstctl history-pop";
    "Print" = "exec grim -g \"$(${scriptDir}/slurp_point.sh)\" - | wl-copy";
  };

  i3Keybindings = scriptDir: {
    "Mod4+d" = "exec rofi -i -modi drun -show drun";
    "Mod4+Shift+v" = "exec rofi -i -modi \"clipboard:greenclip print\" -show clipboard -run-command '{cmd}'";
    "Mod4+Control+v" = "exec greenclip print | head -n 1 | xclip -i -selection \"clipboard\"";
    "Mod4+Shift+Control+v" = "exec xdotool type \"$(greenclip print | head -n 1)\"";
    "Mod4+q" = "exec dunstctl close-all";
    "Mod4+Shift+r" = "exec \"i3-msg reload; feh --bg-fill $HOME/.cache/wallpaper\"";
    "Mod4+Shift+p" = "exec xrandr --output \"$(${scriptDir}/get_focused_output.sh)\" --off";
    "Mod4+c" = "mode \"control\"; exec notify-send \"Control b/t/d\"";
  };

  commonModes = {
    gaps = {
      "0" = "gaps inner current set 0; gaps outer current set 0; gaps top current set 0; gaps bottom current set 0";
      "1" = "gaps inner current set 10; gaps outer current set 10; gaps top current set 10; gaps bottom current set 10";
      "2" = "gaps inner current set 0; gaps outer current set 0";
      "3" = "gaps inner current set 10; gaps outer current set -10";
      "4" = "gaps inner current set 0; gaps outer current set 10; gaps outer current plus 10; gaps top current set 10; gaps bottom current set 10";
      "h" = "gaps horizontal current minus 10";
      "j" = "gaps vertical current plus 10";
      "k" = "gaps vertical current minus 10";
      "l" = "gaps horizontal current plus 10";
      "equal" = "gaps inner current plus 10";
      "minus" = "gaps inner current minus 10";
      "Shift+equal" = "gaps inner current plus 1";
      "Shift+minus" = "gaps inner current minus 1";
      "Return" = "mode \"default\"; exec notify-send \"default\"";
      "Escape" = "mode \"default\"; exec notify-send \"default\"";
      "Mod4+Shift+g" = "mode \"default\"; exec notify-send \"default\"";
    };
  };

  swayModes = scriptDir: {
    system = {
      "l" = "exec loginctl lock-session, mode default; exec notify-send lock";
      "e" = "exec swaymsg exit, mode default; exec notify-send exit";
      "s" = "exec systemctl suspend-then-hibernate, mode default; exec notify-send suspend-then-hibernate";
      "Shift+s" = "exec systemctl suspend, mode default; exec notify-send suspend";
      "h" = "exec systemctl hibernate, mode default; exec notify-send hibernate";
      "r" = "exec systemctl reboot, mode default; exec notify-send reboot";
      "p" = "exec systemctl poweroff -i, mode default; exec notify-send poweroff";
      "u" = "exec systemctl reboot --firmware-setup, mode default; exec notify-send uefi/bios";
      "Return" = "mode default; exec notify-send default";
      "Escape" = "mode default; exec notify-send default";
    };
    idle = {
      "i" = "exec ${scriptDir}/swayidle_inhibit.sh, mode default; exec notify-send inhibit";
      "d" = "exec ${scriptDir}/swayidle_dpms.sh, mode default; exec notify-send dpms";
      "l" = "exec ${scriptDir}/swayidle_lock.sh, mode default; exec notify-send lock";
      "s" = "exec ${scriptDir}/swayidle_suspend.sh, mode default; exec notify-send suspend";
      "Shift+s" = "exec ${scriptDir}/swayidle_suspend_long.sh, mode default; exec notify-send suspend_long";
      "Shift+l" = "exec ${scriptDir}/swayidle_lock_no_dpms.sh, mode default; exec notify-send \"lock no dpms\"";
      "Return" = "mode default; exec notify-send default";
      "Escape" = "mode default; exec notify-send default";
    };
    capture = {
      "q" = "exec dunstctl close";
      "c" = "exec grim -g \"\$(${scriptDir}/slurp_point.sh)\" - | wl-copy, mode default";
      "e" = "exec grim -g \"\$(${scriptDir}/slurp_point.sh)\" - | swappy -f -, mode default";
      "f" = "exec grim -g \"\$(${scriptDir}/slurp_point.sh)\" \$XDG_PICTURES_DIR/\"\$(date '+%Y-%m-%d %H.%M.%S')\".png, mode default";
      "Shift+c" = "exec grim - | wl-copy, mode default; exec notify-send copied";
      "Shift+e" = "exec grim - | swappy -f -, mode default; exec notify-send saved";
      "Shift+f" = "exec grim \$XDG_PICTURES_DIR/\"\$(date '+%Y-%m-%d %H.%M.%S')\".png, mode default; exec notify-send \"saved to file\"";
      "v" = "exec wf-recorder -a=\"\$(pactl info | sed -En 's/Default Sink: (.*)/\\1/p').monitor\" -o \$(swaymsg -t get_outputs | jq -r '.[] | select(.type==\"output\" and .focused).name') -f \$XDG_VIDEOS_DIR/\"\$(date '+%Y-%m-%d %H.%M')\".mp4, mode default";
      "Shift+v" = "exec pkill -SIGINT wf-recorder; exec notify-send \"stop recording\"";
      "Return" = "mode default; exec notify-send default";
      "Escape" = "mode default; exec notify-send default";
    };
    passthrough = {
      "Mod4+Delete" = "mode default; exec notify-send \"passthrough off\"";
    };
    mouse = {
      "a" = "mode default, exec wl-kbptr; swaymsg mode Mouse";
      "h" = "seat seat0 cursor move -15 0";
      "j" = "seat seat0 cursor move 0 15";
      "k" = "seat seat0 cursor move 0 -15";
      "l" = "seat seat0 cursor move 15 0";
      "s" = "seat seat0 cursor press button1";
      "--release s" = "seat seat0 cursor release button1";
      "d" = "seat seat0 cursor press button2";
      "--release d" = "seat seat0 cursor release button2";
      "f" = "seat seat0 cursor press button3";
      "--release f" = "seat seat0 cursor release button3";
      "Return" = "mode default; exec notify-send default; seat seat0 hide_cursor when-typing enable";
      "Escape" = "mode default; exec notify-send default; seat seat0 hide_cursor when-typing enable";
    };
    control_backlight = {
      "minus" = "exec brightnessctl set 10%-; exec st backlight -t 500";
      "equal" = "exec brightnessctl set 10%+; exec st backlight -t 500";
      "Shift+equal" = "exec brightnessctl set 1%+; exec st backlight -t 500";
      "Shift+minus" = "exec brightnessctl set 1%-; exec st backlight -t 500";
      "Control+equal" = "exec brightnessctl set 5%+; exec st backlight -t 500";
      "Control+minus" = "exec brightnessctl set 5%-; exec st backlight -t 500";
      "Return" = "mode default; exec notify-send default";
      "Escape" = "mode default; exec notify-send default";
    };
    control_dwt = {
      "e" = "input type:touchpad dwt enabled, mode default; exec notify-send enabled";
      "d" = "input type:touchpad dwt disabled, mode default; exec notify-send disabled";
      "Return" = "mode default; exec notify-send default";
      "Escape" = "mode default; exec notify-send default";
    };
    control_outputs = {
      "e" = "output * enable; output * dpms on, mode default";
      "d" = "exec swaymsg output \"\$(${scriptDir}/get_focused_output.sh)\" disable";
      "Return" = "mode default; exec notify-send default";
      "Escape" = "mode default; exec notify-send default";
    };
    control = {
      "b" = "mode control_backlight; exec notify-send \"Control backlight | -/+\"";
      "t" = "mode control_dwt; exec notify-send \"Control DWT | (e)nabled (d)isabled\"";
      "d" = "exec ${scriptDir}/dpms_off.sh; exec notify-send \"DPMS Off\", mode default";
      "o" = "mode control_outputs; exec notify-send \"Control Outputs | (e)nable (d)isable\"";
      "Return" = "mode default; exec notify-send default";
      "Escape" = "mode default; exec notify-send default";
    };
  };

  i3Modes = scriptDir: {
    system = {
      "l" = "exec loginctl lock-session, mode \"default\"; exec notify-send \"lock\"";
      "e" = "exec i3-msg exit, mode \"default\"; exec notify-send \"exit\"";
      "s" = "exec systemctl suspend, mode \"default\"; exec notify-send \"suspend\"";
      "h" = "exec systemctl hibernate, mode \"default\"; exec notify-send \"hibernate\"";
      "r" = "exec systemctl reboot, mode \"default\"; exec notify-send \"reboot\"";
      "p" = "exec systemctl poweroff -i, mode \"default\"; exec notify-send \"poweroff\"";
      "u" = "exec systemctl reboot --firmware-setup, mode \"default\"; exec notify-send \"uefi/bios\"";
      "Shift+s" = "exec systemctl suspend-then-hibernate, mode \"default\"; exec notify-send \"suspend-then-hibernate\"";
      "Return" = "mode \"default\"; exec notify-send \"default\"";
      "Escape" = "mode \"default\"; exec notify-send \"default\"";
    };
    control = {
      "b" = "mode \"control_backlight\"; exec notify-send \"Control backlight | -/+\"";
      "t" = "mode \"control_dwt\"; exec notify-send \"Control DWT | (e)nabled (d)isabled\"";
      "d" = "exec ${scriptDir}/dpms_off.sh; exec notify-send \"DPMS Off\"; mode \"default\"";
      "Return" = "mode \"default\"; exec notify-send \"default\"";
      "Escape" = "mode \"default\"; exec notify-send \"default\"";
    };
  };

  commonStartup = [
    { command = "gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'"; always = true; }
  ];

  swayStartup = idle: scriptDir: set_wallpaper: [
    { command = "${scriptDir}/swayidle_${idle}.sh"; always = true; }
    { command = "systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP SWAYSOCK"; }
    { command = "pkill -f dunst_restart; ${scriptDir}/dunst_restart.sh"; always = true; }
    {
      command = set_wallpaper;
      always = true;
    }
    { command = "pkill -f laptop_clamshell; ${scriptDir}/laptop_clamshell.sh"; always = true; }
  ];

  i3Startup = scriptDir: set_wallpaper: [
    { command = "${i3-workspace-history}/bin/i3-workspace-history"; }
    { command = "xss-lock --transfer-sleep-lock -- xsecurelock"; }
    { command = "greenclip daemon"; }
    { command = "systemctl --user start redshift"; }
    { command = "systemctl --user import-environment XAUTHORITY DISPLAY"; }
    { command = "xinput set-prop 'Logitech Gaming Mouse G502' 'libinput Accel Profile Enabled' 0, 1"; }
    { command = "xinput set-prop 'DLL0945:00 06CB:CDE6 Touchpad' 'libinput Natural Scrolling Enabled' 1"; }
    { command = "xrandr --output DP-1-2 --primary --mode 2560x1440 --pos 0x0 --rotate normal --output DP-1-3 --mode 1920x1080 --pos 2560x0 --rotate left"; }
    {
      command = set_wallpaper;
      always = true;
    }
  ];
}
