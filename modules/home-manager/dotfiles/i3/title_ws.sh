#!/usr/bin/env bash
PROMPT='Title workspace: '
DEFAULT=$($(dirname "$0")/get_cur_ws_name.sh)
NAME=$(rofi -dmenu -lines 0 -p "$PROMPT" -filter "$DEFAULT")

i3-msg rename workspace to \"$NAME\"
