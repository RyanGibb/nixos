#!/usr/bin/env bash

NEW_WS_NUM="$($(dirname "$0")/get_free_ws_num.sh)" || exit 1

WORKSPACES="$(@wmmsg@ -t get_workspaces | jq -r '.[] | .name')"
WORKSPACES="${WORKSPACES}
$NEW_WS_NUM"

NAME=$(echo "$WORKSPACES" | wofi -d -i -o default -p "Select workspace:") || exit 1
echo "$NAME"

