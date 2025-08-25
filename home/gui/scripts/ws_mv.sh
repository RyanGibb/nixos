#!/usr/bin/env bash

NAME="$(eval "$1")" || exit
ID="$($(dirname "$0")/get_cur_focus_id.sh)"
$(dirname "$0")/focus_on_id.sh "$ID"
@wmmsg@ move container to workspace \"$NAME\"

notify-send "$NAME" -t 500
