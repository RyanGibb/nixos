#!/usr/bin/env bash
choice=$(printf 'c - copy region
e - edit region
f - save region to file
C - copy screen
E - edit screen
F - save screen to file
v - record video
V - stop recording' | wofi -d -i -p 'capture')
case "${choice:0:1}" in
  c) ~/.config/sway/scripts/capture_region.sh | wl-copy ;;
  e) ~/.config/sway/scripts/capture_region.sh | swappy -f - ;;
  f) ~/.config/sway/scripts/capture_region.sh > "$XDG_PICTURES_DIR/capture/$(date '+%Y-%m-%d %H.%M.%S').png" ;;
  C) grim - | wl-copy ;;
  E) grim - | swappy -f - ;;
  F) grim "$XDG_PICTURES_DIR/capture/$(date '+%Y-%m-%d %H.%M.%S').png" ;;
  v)
    output=$(niri msg --json focused-output | jq -r .name)
    sink="$(pactl info | sed -En 's/Default Sink: (.*)/\1/p').monitor"
    wf-recorder -a="$sink" -o "$output" -f "$XDG_VIDEOS_DIR/$(date '+%Y-%m-%d %H.%M').mp4" &
    ;;
  V) pkill -SIGINT wf-recorder ;;
esac
[ -n "$choice" ] && notify-send "$choice"
