#!/usr/bin/env bash
choice=$(printf 'region-to-clip\nregion-to-editor\nregion-to-file\nscreen-to-clip\nscreen-to-editor\nscreen-to-file\nrecord-video\nstop-recording' | wofi -d -i -p 'capture')
case "$choice" in
  region-to-clip)
    ~/.config/sway/scripts/capture_region.sh | wl-copy ;;
  region-to-editor)
    ~/.config/sway/scripts/capture_region.sh | swappy -f - ;;
  region-to-file)
    ~/.config/sway/scripts/capture_region.sh > "$XDG_PICTURES_DIR/capture/$(date '+%Y-%m-%d %H.%M.%S').png" ;;
  screen-to-clip)
    grim - | wl-copy ;;
  screen-to-editor)
    grim - | swappy -f - ;;
  screen-to-file)
    grim "$XDG_PICTURES_DIR/capture/$(date '+%Y-%m-%d %H.%M.%S').png" ;;
  record-video)
    output=$(niri msg --json focused-output | jq -r .name)
    sink=$(pactl info | sed -En 's/Default Sink: (.*)/\1/p').monitor
    wf-recorder -a="$sink" -o "$output" -f "$XDG_VIDEOS_DIR/$(date '+%Y-%m-%d %H.%M').mp4" &
    ;;
  stop-recording)
    pkill -SIGINT wf-recorder ;;
esac
[ -n "$choice" ] && notify-send "$choice"
