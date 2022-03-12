#!/usr/bin/env bash

NEW_WS_NUM="$($(dirname "$0")/get_free_ws_num.sh)"
swaymsg move container to workspace \"$NEW_WS_NUM\"
