#!/usr/bin/env bash

NEW_WS_NUM="$($(dirname "$0")/get_free_ws_num.sh)"

WORKSPACES=$(swaymsg -t get_workspaces \
  | jq '.[].name'\
  | cut -d"\"" -f2\
  | sort
)
WORKSPACES="${WORKSPACES}
$NEW_WS_NUM"

NAME=$(echo "$WORKSPACES" | wofi -d -p "Select workspace:") || exit
echo "$NAME"
