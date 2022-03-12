#!/usr/bin/env bash

ws_nums=($(swaymsg -t get_workspaces \
	| jq '[.[] | select(.num != -1) | .num ] | sort | .[]'))

# find first non-sequential element of ws_nums from i
v=1
for ws_num in ${ws_nums[@]}; do
	if [ "$ws_num" -ne "$v" ]; then
		echo "$v"
		exit 0
	fi
	((v++))
done

echo "$v"
