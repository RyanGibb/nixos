#!/usr/bin/env bash

workspaces="$($(dirname $0)/get_free_ws_num.sh)
$(swaymsg -t get_workspaces | jq -r '.[] | .name')"

selected="$(echo "$workspaces" | wofi -d -i -o default -p "Select workspace:")" || exit 1

swaymsg workspace "$selected"

