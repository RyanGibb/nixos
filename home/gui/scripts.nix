{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom.gui;

  # Handy pinned tool paths for readability.
  jq = "${pkgs.jq}/bin/jq";
  yad = "${pkgs.yad}/bin/yad";
  wofi = "${pkgs.wofi}/bin/wofi";
  rofi = "${pkgs.rofi}/bin/rofi";
  swaybg = "${pkgs.swaybg}/bin/swaybg";
  slurp = "${pkgs.slurp}/bin/slurp";
  grim = "${pkgs.grim}/bin/grim";
  wayfreeze = "${pkgs.wayfreeze}/bin/wayfreeze";
  swayidle = "${pkgs.swayidle}/bin/swayidle";
  swaylock = "${pkgs.swaylock}/bin/swaylock";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  bluetoothctl = "${pkgs.bluez}/bin/bluetoothctl";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
  clipman = "${pkgs.clipman}/bin/clipman";
  wtype = "${pkgs.wtype}/bin/wtype";
  loginctl = "${pkgs.systemd}/bin/loginctl";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  notifySend = "${pkgs.libnotify}/bin/notify-send";
  wl-kbptr = "${pkgs.wl-kbptr}/bin/wl-kbptr";
  dunstctl = "${pkgs.dunst}/bin/dunstctl";
  wlrctl = "${pkgs.wlrctl}/bin/wlrctl";

  locker = "${swaylock} -f -i $HOME/.cache/wallpaper";

  # ---- Compositor-agnostic helpers ----

  wm-dpms = pkgs.writeShellScriptBin "wm-dpms" ''
    # Compositor-agnostic DPMS/output control.
    # Usage: wm-dpms on|off|enable
    case "$XDG_CURRENT_DESKTOP:$1" in
      niri:enable) for o in $(niri msg -j outputs | ${jq} -r 'keys[]'); do niri msg output "$o" on; done ;;
      niri:*)      niri msg action "power-$1-monitors" ;;
      *:enable)    swaymsg "output * enable" ;;
      *)           swaymsg "output * dpms $1" ;;
    esac
  '';

  wm-wall = pkgs.writeShellScriptBin "wm-wall" ''
    # Re-apply the wallpaper from $HOME/.cache/wallpaper.
    case "$XDG_CURRENT_DESKTOP" in
      sway) swaymsg "output * bg $HOME/.cache/wallpaper fill #282828" ;;
      *)    pkill -x swaybg
            ${swaybg} -i "$HOME/.cache/wallpaper" -m fill -c '#282828' & ;;
    esac
  '';

  wm-wall-set = pkgs.writeShellScriptBin "wm-wall-set" ''
    ln -sf "$1" "$HOME/.cache/wallpaper" || exit 1
    exec wm-wall
  '';

  wm-wall-random = pkgs.writeShellScriptBin "wm-wall-random" ''
    ln -sf "$(find "$WALLPAPER_DIR" -type f | sort -R | tail -1)" "$HOME/.cache/wallpaper"
    exec wm-wall
  '';

  wm-wall-pick = pkgs.writeShellScriptBin "wm-wall-pick" ''
    WALLPAPER=$(find "$WALLPAPER_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' \
      | sort \
      | while read -r A ; do printf '%s\0icon\x1f%s/%s\n' "$A" "$WALLPAPER_DIR" "$A"; done \
      | ${rofi} -dmenu -p "$(basename "$(readlink -f "$HOME/.cache/wallpaper")")") || exit 1
    ln -sf "$WALLPAPER_DIR/$WALLPAPER" "$HOME/.cache/wallpaper" || exit 1
    exec wm-wall
  '';

  wm-capture-region = pkgs.writeShellScriptBin "wm-capture-region" ''
    # Freeze screen, two-point region selection, capture PNG to stdout.
    set -o pipefail
    ${wayfreeze} &
    pid=$!
    trap 'kill $pid 2>/dev/null' EXIT
    sleep 0.1

    point="$(${slurp} -p | cut -d \  -f 1)" || exit
    IFS=',' read -ra coord <<< "$point"
    x1="''${coord[0]}"; y1="''${coord[1]}"

    point="$(${slurp} -p | cut -d \  -f 1)" || exit
    IFS=',' read -ra coord <<< "$point"
    x2="''${coord[0]}"; y2="''${coord[1]}"

    if ((x1 < x2)); then w=$((x2 - x1)); x=$x1; else w=$((x1 - x2)); x=$x2; fi
    if ((y1 < y2)); then h=$((y2 - y1)); y=$y1; else h=$((y1 - y2)); y=$y2; fi

    ${grim} -g "$x,$y ''${w}x''${h}" -
  '';

  wm-cycle-sink = pkgs.writeShellScriptBin "wm-cycle-sink" ''
    mapfile -t sink_ids < <(${pactl} list short sinks | cut -f 1)
    mapfile -t sinks    < <(${pactl} list short sinks | cut -f 2)
    default_sink=$(${pactl} info | sed -En 's/Default Sink: (.*)/\1/p')

    for i in "''${!sinks[@]}"; do
      if [[ "''${sinks[$i]}" = "''${default_sink}" ]]; then break; fi
    done

    if [[ "$1" == "back" ]]; then j=-1; else j=1; fi
    prev_i=$i

    while true; do
      i=$(((i+j)%''${#sinks[@]}))
      if ! ${pactl} list sinks | sed -n "/Sink #''${sink_ids[$i]}/,\$p" | grep "\[Out\]" | head -n 1 | grep "not available"; then
        ${pactl} set-default-sink "''${sinks[$i]}"
        break
      fi
      if [ "$prev_i" -eq "$i" ]; then break; fi
    done
  '';

  wm-pause-player = pkgs.writeShellScriptBin "wm-pause-player" ''
    ${playerctl} play-pause -p "$(${playerctl} -l | sed -n "$1p")"
  '';

  wm-bluetooth = pkgs.writeShellScriptBin "wm-bluetooth" ''
    bt_cmd=''${1:-connect}
    devices="$(echo 'devices' | ${bluetoothctl} | grep '^Device' | sed "s/^[^ ]* //")"
    awk -v bt_cmd="$bt_cmd" '{printf("power on\n%s %s\n", bt_cmd, $1)}' < <(\
      echo "$devices" | ${wofi} -d -i -p "Select device to $bt_cmd:"
    ) > >(${bluetoothctl})
  '';

  wm-wifi = pkgs.writeShellScriptBin "wm-wifi" ''
    set -o pipefail
    ssid="$(\
      ${nmcli} -g IN-USE,SSID,SIGNAL,BARS,SECURITY dev wifi list \
      | awk -F: '$2 != "" && !seen[$2]++ {printf "%s %s %s %s\t%s\n", $1, $4, $3, $5, $2}' \
      | ${wofi} -d "Select network:" \
      | cut -f2-
    )" || exit
    ${nmcli} dev wifi connect "$ssid"
  '';

  wm-network-connect = pkgs.writeShellScriptBin "wm-network-connect" ''
    mac_addr="$(${nmcli} con show | tail -n +2 | ${wofi} -d -i -p "Select network:" | awk '{print $(NF-2)}')"
    ${nmcli} con up "$mac_addr"
  '';

  wm-open-file = pkgs.writeShellScriptBin "wm-open-file" ''
    FILE="$(${pkgs.fzf}/bin/fzf)" || exit 1
    ${pkgs.xdg-utils}/bin/xdg-open "$FILE" & disown
    zsh -i
  '';

  wm-vault = pkgs.writeShellScriptBin "wm-vault" ''
    file="$(date '+%Y-%m-%d').md"
    cd ~/vault || exit
    ${pkgs.vim}/bin/vim "$file"
  '';

  wm-vault-titled = pkgs.writeShellScriptBin "wm-vault-titled" ''
    title="$(${yad} --entry --text=Title:)" || exit
    file="$(date '+%Y-%m-%d') $title.md"
    cd ~/vault || exit
    ${pkgs.vim}/bin/vim "$file"
  '';

  wm-rename = pkgs.writeShellScriptBin "wm-rename" ''
    # Rename focused workspace via yad prefilled with current name. Empty input unsets.
    case "$XDG_CURRENT_DESKTOP" in
      niri) cur=$(niri msg --json workspaces | ${jq} -r '.[] | select(.is_focused) | .name // ""') ;;
      *)    cur=$(swaymsg -t get_workspaces | ${jq} -r '.[] | select(.focused) | .name') ;;
    esac
    name=$(${yad} --entry --text 'Workspace name (empty to unset):' --entry-text="$cur") || exit 0
    case "$XDG_CURRENT_DESKTOP" in
      niri) if [ -z "$name" ]; then niri msg action unset-workspace-name
            else niri msg action set-workspace-name "$name"; fi ;;
      *)    swaymsg rename workspace to "\"$name\"" ;;
    esac
  '';

  # ---- Dispatched: focused window / workspace / output primitives ----

  wm-focus-id = pkgs.writeShellScriptBin "wm-focus-id" ''
    # Focus window by id ($1). sway con_id, niri window id.
    case "$XDG_CURRENT_DESKTOP" in
      niri) niri msg action focus-window --id "$1" ;;
      *)    swaymsg "[con_id=$1] focus" ;;
    esac
  '';

  wm-focus-id-get = pkgs.writeShellScriptBin "wm-focus-id-get" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) niri msg --json focused-window | ${jq} -r '.id // empty' ;;
      *)    swaymsg -t get_tree \
              | ${jq} -r 'recurse(.nodes[], .floating_nodes[];.nodes!=null) | select(.focused==true).id' ;;
    esac
  '';

  wm-ws-name = pkgs.writeShellScriptBin "wm-ws-name" ''
    if [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
      niri msg --json workspaces \
        | ${jq} -r '.[] | select(.is_focused == true) | if .name then "\(.idx):\(.name)" else "\(.idx)" end'
    elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
      swaymsg -t get_workspaces | ${jq} -r '.[] | select(.focused==true) | .name'
    elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
      i3-msg -t get_workspaces | ${jq} -r '.[] | select(.focused==true) | .name'
    fi
  '';

  wm-output-focused = pkgs.writeShellScriptBin "wm-output-focused" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) niri msg --json focused-output | ${jq} -r '.name' ;;
      *)    swaymsg -t get_tree \
              | ${jq} -r '.nodes[] | select([recurse(.nodes[]?, .floating_nodes[]?) | .focused] | any) | .name' ;;
    esac
  '';

  wm-ws-free = pkgs.writeShellScriptBin "wm-ws-free" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri)
        # niri creates workspaces dynamically; return max(idx)+1 on the focused output.
        out=$(niri msg --json focused-output | ${jq} -r '.name')
        niri msg --json workspaces \
          | ${jq} --arg out "$out" -r '[.[] | select(.output==$out) | .idx] | (max // 0) + 1'
        ;;
      *)
        mapfile -t ws_nums < <(swaymsg -t get_workspaces \
          | ${jq} '[.[] | select(.num != -1) | .num] | sort | .[]')
        last=0
        for ws_num in "''${ws_nums[@]}"; do
          if [ $(("$ws_num" - "$last")) -gt 1 ]; then break; fi
          last="$ws_num"
        done
        echo $(("$last" + 1))
        ;;
    esac
  '';

  wm-ws-select = pkgs.writeShellScriptBin "wm-ws-select" ''
    NEW_WS_NUM="$(wm-ws-free)" || exit 1
    case "$XDG_CURRENT_DESKTOP" in
      niri) WORKSPACES="$(niri msg --json workspaces | ${jq} -r '.[] | .name // (.idx | tostring)')" ;;
      *)    WORKSPACES="$(swaymsg -t get_workspaces | ${jq} -r '.[] | .name')" ;;
    esac
    WORKSPACES="''${WORKSPACES}
$NEW_WS_NUM"
    NAME=$(echo "$WORKSPACES" | ${wofi} -d -i -p "Select workspace:" -o default) || exit 1
    echo "$NAME"
  '';

  wm-ws-switch = pkgs.writeShellScriptBin "wm-ws-switch" ''
    NAME="$(eval "$1")" || exit
    case "$XDG_CURRENT_DESKTOP" in
      niri) niri msg action focus-workspace "$NAME" ;;
      *)    swaymsg workspace "\"$NAME\"" ;;
    esac
    ${notifySend} "$NAME" -t 500
  '';

  wm-ws-mv = pkgs.writeShellScriptBin "wm-ws-mv" ''
    NAME="$(eval "$1")" || exit
    case "$XDG_CURRENT_DESKTOP" in
      niri) niri msg action move-column-to-workspace "$NAME" ;;
      *)    ID="$(wm-focus-id-get)"
            wm-focus-id "$ID"
            swaymsg move container to workspace "\"$NAME\"" ;;
    esac
    ${notifySend} "$NAME" -t 500
  '';

  wm-ws-switch-mv = pkgs.writeShellScriptBin "wm-ws-switch-mv" ''
    NAME="$(eval "$1")" || exit
    case "$XDG_CURRENT_DESKTOP" in
      niri) niri msg action move-column-to-workspace "$NAME"
            niri msg action focus-workspace "$NAME" ;;
      *)    ID="$(wm-focus-id-get)"
            wm-focus-id "$ID"
            swaymsg move container to workspace "\"$NAME\""
            swaymsg workspace "\"$NAME\""
            wm-focus-id "$ID" ;;
    esac
    ${notifySend} "$NAME" -t 500
  '';

  wm-ws-mv-prev = pkgs.writeShellScriptBin "wm-ws-mv-prev" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) ID="$(niri msg --json focused-window | ${jq} -r '.id // empty')"
            [ -n "$ID" ] || exit 0
            FROM="$(niri msg --json workspaces | ${jq} -r '.[] | select(.is_focused) | .id')"
            niri msg action focus-workspace-previous
            TO="$(niri msg --json workspaces | ${jq} -r '.[] | select(.is_focused) | .id')"
            # focus-workspace-previous is a no-op when there is no previous workspace
            [ "$TO" != "$FROM" ] || exit 0
            IDX="$(niri msg --json workspaces | ${jq} -r '.[] | select(.is_focused) | .idx')"
            niri msg action move-window-to-workspace --window-id "$ID" "$IDX"
            # --focus only follows a window that is still focused, and we already left it
            niri msg action focus-window --id "$ID" ;;
      *)    ID="$(wm-focus-id-get)"
            wm-focus-id "$ID"
            swaymsg move container to workspace back_and_forth
            swaymsg workspace back_and_forth
            wm-focus-id "$ID" ;;
    esac
  '';

  wm-clamshell = pkgs.writeShellScriptBin "wm-clamshell" ''
    laptop_output=eDP-1
    if grep -q closed /proc/acpi/button/lid/LID*/state; then
      state_sway=disable; state_niri=off
    else
      state_sway=enable;  state_niri=on
    fi
    case "$XDG_CURRENT_DESKTOP" in
      niri) niri msg output "$laptop_output" "$state_niri" ;;
      *)    swaymsg output "$laptop_output" "$state_sway" ;;
    esac
  '';

  wm-lock-if-solo = pkgs.writeShellScriptBin "wm-lock-if-solo" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) count=$(niri msg --json outputs | ${jq} 'length') ;;
      *)    count=$(swaymsg -t get_outputs | grep -c '"type": "output"') ;;
    esac
    if [ "$count" = "1" ]; then
      ${loginctl} lock-session
    fi
  '';

  wm-dpms-toggle = pkgs.writeShellScriptBin "wm-dpms-toggle" ''
    lockfile=/tmp/screen-off-lock
    if [ -f "$lockfile" ]; then
      rm "$lockfile"
      wm-dpms enable
      wm-dpms on
    else
      touch "$lockfile"
      wm-dpms off
    fi
  '';

  wm-dunst-watch = pkgs.writeShellScriptBin "wm-dunst-watch" ''
    # Restart dunst when the set of outputs changes.
    case "$XDG_CURRENT_DESKTOP" in
      niri)
        prev=""
        while true; do
          cur=$(niri msg --json outputs | ${jq} -S '.' | sha256sum | cut -d' ' -f1)
          if [ -n "$prev" ] && [ "$cur" != "$prev" ]; then
            pkill dunst
          fi
          prev="$cur"
          sleep 3
        done
        ;;
      *)
        while true; do
          swaymsg -t subscribe '["output"]'
          sleep 3
          pkill dunst
        done
        ;;
    esac
  '';

  wm-window-switcher = pkgs.writeShellScriptBin "wm-window-switcher" ''
    # Global window picker; wofi menu, focuses the chosen window.
    set -o pipefail
    case "$XDG_CURRENT_DESKTOP" in
      niri)
        id=$(niri msg --json windows \
          | ${jq} -r '.[] | "\(.id)\t\(.app_id // "?")  \(.title // "")"' \
          | ${wofi} -d -i -p 'window' \
          | awk '{print $1}') || exit 0
        [ -n "$id" ] && niri msg action focus-window --id "$id"
        ;;
      *)
        id=$(swaymsg -t get_tree \
          | ${jq} -r '
              recurse(.nodes[], .floating_nodes[]; .nodes != null)
              | select((.type=="con" or .type=="floating_con") and .name != null)
              | "\(.id)\t\(.app_id // .window_properties.class // "?")  \(.name)"' \
          | ${wofi} -d -i -p 'window' \
          | awk '{print $1}') || exit 0
        [ -n "$id" ] && swaymsg "[con_id=$id] focus"
        ;;
    esac
  '';

  # ---- Error under niri; sway impl below ----

  wm-focus-leaf = pkgs.writeShellScriptBin "wm-focus-leaf" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) echo "wm-focus-leaf: niri has no window tree; use focus-column-right/left" >&2; exit 1 ;;
    esac
    ID=0
    while [[ "$ID" != "$PREV_ID" ]]; do
      PREV_ID=$ID
      ID=$(wm-focus-id-get)
      swaymsg focus child
    done
  '';

  wm-focus-root = pkgs.writeShellScriptBin "wm-focus-root" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) echo "wm-focus-root: niri has no window tree" >&2; exit 1 ;;
    esac
    ID=0
    while [[ "$ID" != "$PREV_ID" ]]; do
      PREV_ID=$ID
      ID=$(wm-focus-id-get)
      swaymsg focus parent
    done
  '';

  wm-tab-windows = pkgs.writeShellScriptBin "wm-tab-windows" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) echo "wm-tab-windows: niri has no sway-style tabbed containers; use recent-windows or toggle-column-tabbed-display" >&2; exit 1 ;;
    esac
    jq_cmd="recurse(.nodes[];.nodes!=null) |"
    cur_ws_id="$(swaymsg -t get_workspaces | ${jq} '.[] | select(.focused==true).id')"
    jq_cmd+="select(.id==$cur_ws_id).nodes | .[] | recurse(.nodes[];.nodes!=null) | select(.nodes==[])"
    windows="$(swaymsg -t get_tree | ${jq} -r "$jq_cmd")"

    mapfile -t windows_focused < <(echo "$windows" | ${jq} '.focused')
    mapfile -t windows_id      < <(echo "$windows" | ${jq} '.id')
    i=0
    for focused in "''${windows_focused[@]}"; do
      if [ "$focused" == "true" ]; then break; fi
      ((i++))
    done
    if   [[ "$1" == "back" ]];    then ((i--))
    elif [[ "$1" == "forward" ]]; then ((i++))
    fi
    i=$((i % ''${#windows_focused[@]}))
    wm-focus-id "''${windows_id[$i]}"
  '';

  wm-scratch-switcher = pkgs.writeShellScriptBin "wm-scratch-switcher" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) echo "wm-scratch-switcher: niri has no scratchpad" >&2; exit 1 ;;
    esac
    windows=$(swaymsg -t get_tree | ${jq} -r '
      recurse(.nodes[], .floating_nodes[];.nodes!=null)
      | select(.name=="__i3_scratch")
      | recurse(.nodes[], .floating_nodes[];.nodes!=null)
      | select((.type=="con" or .type=="floating_con") and .name!=null)
      | "\(.id? | tostring | (" " * (3 - length)) + .) \(.name?)"')
    selected=$(echo "$windows" | ${wofi} -d -i -p "Select window:" | awk '{print $1}')
    swaymsg "[con_id=$selected] focus"
  '';

  wm-slurp-windows = pkgs.writeShellScriptBin "wm-slurp-windows" ''
    case "$XDG_CURRENT_DESKTOP" in
      niri) echo "wm-slurp-windows: no niri equivalent for whole-window rects" >&2; exit 1 ;;
    esac
    swaymsg -t get_tree \
      | ${jq} -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' \
      | ${slurp}
  '';

  # ---- swayidle policies. swayidle works under niri via ext-idle-notify. ----

  wm-idle-kanshi = pkgs.writeShellScriptBin "wm-idle-kanshi" ''
    # Apply a swayidle policy on kanshi profile change; skip when profile is unchanged
    # so manual idle-mode picks aren't clobbered by a redundant kanshi re-apply.
    profile="$1"
    script="$2"
    state="''${XDG_RUNTIME_DIR:-/tmp}/kanshi_profile"
    if [ "$(cat "$state" 2>/dev/null)" = "$profile" ]; then exit 0; fi
    echo "$profile" >"$state"
    exec "$script"
  '';

  wm-idle-inhibit = pkgs.writeShellScriptBin "wm-idle-inhibit" ''
    pkill -x swayidle
    ${swayidle} -w \
      lock '${locker}' \
      before-sleep '${playerctl} -a pause; ${loginctl} lock-session'
  '';

  wm-idle-dpms = pkgs.writeShellScriptBin "wm-idle-dpms" ''
    pkill -x swayidle
    ${swayidle} -w \
      lock '${locker}' \
      timeout 120 "${notifySend} 'going to sleep soon!' -t 3000" \
      timeout 180 'wm-dpms off' \
        resume 'wm-dpms on' \
      before-sleep '${playerctl} -a pause; ${loginctl} lock-session'
  '';

  wm-idle-lock = pkgs.writeShellScriptBin "wm-idle-lock" ''
    pkill -x swayidle
    ${swayidle} -w \
      lock '${locker}' \
      timeout 120 "${notifySend} 'going to sleep soon!' -t 3000" \
      timeout 180 'wm-dpms off' \
        resume 'wm-dpms on' \
      timeout 240 '${loginctl} lock-session' \
      before-sleep '${playerctl} -a pause; ${loginctl} lock-session'
  '';

  wm-idle-lock-no-dpms = pkgs.writeShellScriptBin "wm-idle-lock-no-dpms" ''
    pkill -x swayidle
    ${swayidle} -w \
      lock '${locker}' \
      timeout 120 "${notifySend} 'going to lock soon!' -t 3000" \
      timeout 240 '${loginctl} lock-session' \
      before-sleep '${playerctl} -a pause; ${loginctl} lock-session'
  '';

  wm-idle-suspend = pkgs.writeShellScriptBin "wm-idle-suspend" ''
    pkill -x swayidle
    ${swayidle} -w \
      lock '${locker}' \
      timeout 120 "${notifySend} 'going to sleep soon!' -t 3000" \
      timeout 180 'wm-dpms off' \
        resume 'wm-dpms on' \
      timeout 240 '${loginctl} lock-session' \
      timeout 300 '${systemctl} suspend-then-hibernate' \
      before-sleep '${playerctl} -a pause; ${loginctl} lock-session'
  '';

  wm-idle-suspend-long = pkgs.writeShellScriptBin "wm-idle-suspend-long" ''
    pkill -x swayidle
    ${swayidle} -w \
      lock '${locker}' \
      timeout 3300 "${notifySend} 'going to sleep soon!' -t 300000" \
      timeout 3600 'wm-dpms off' \
        resume 'wm-dpms enable; wm-dpms on' \
      timeout 7200 '${systemctl} suspend' \
      before-sleep '${playerctl} -a pause'
  '';

  allBins = [
    wm-dpms wm-wall wm-wall-set wm-wall-random wm-wall-pick
    wm-capture-region wm-cycle-sink wm-pause-player
    wm-bluetooth wm-wifi wm-network-connect
    wm-open-file wm-vault wm-vault-titled
    wm-rename
    wm-focus-id wm-focus-id-get wm-ws-name wm-output-focused
    wm-ws-free wm-ws-select wm-ws-switch wm-ws-mv wm-ws-switch-mv wm-ws-mv-prev
    wm-clamshell wm-lock-if-solo wm-dpms-toggle wm-dunst-watch wm-window-switcher
    wm-focus-leaf wm-focus-root wm-tab-windows wm-scratch-switcher wm-slurp-windows
    wm-idle-kanshi wm-idle-inhibit wm-idle-dpms wm-idle-lock wm-idle-lock-no-dpms
    wm-idle-suspend wm-idle-suspend-long
  ];
in
{
  config = lib.mkIf cfg.enable {
    home.packages = allBins;
  };
}
