#!/usr/bin/env bash

ID="$($(dirname "$0")/get_cur_focus_id.sh)"
NEW_WS_NUM="$($(dirname "$0")/get_free_ws_num.sh)"

$(dirname "$0")/focus_on_id.sh "$ID"

swaymsg move container to workspace \"$NEW_WS_NUM\"
swaymsg workspace \"$NEW_WS_NUM\"

$(dirname "$0")/focus_on_id.sh "$ID"
