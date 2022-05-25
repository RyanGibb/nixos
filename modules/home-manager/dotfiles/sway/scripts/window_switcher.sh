#!/usr/bin/env bash

windows=$(\
	swaymsg -t get_tree |\
	jq -r '
		recurse(.nodes[], .floating_nodes[];.nodes!=null)
		| select((.type=="con" or .type=="floating_con") and .name!=null)
		| "\(.id? | tostring | (" " * (3 - length)) + .) \(.app_id? // .window_properties.class?) - \(.name?)"
	'
)

selected=$(echo "$windows" | wofi -d -i -p "Select window:" | awk '{print $1}')

swaymsg "[con_id="$selected"] focus"
