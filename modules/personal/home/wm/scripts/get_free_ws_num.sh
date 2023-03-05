#!/usr/bin/env bash

ws_nums=($(@wmmsg@ -t get_workspaces \
	| jq '[.[] | select(.num != -1) | .num ] | sort | .[]'))

# find first element of ws_nums that has a delta between it and it's predecessor greater than 1
last=0
for ws_num in ${ws_nums[@]}; do
	if [ $(("$ws_num" - "$last")) -gt 1 ]; then
		break
	fi
	last="$ws_num"
done

echo $(("$last" + 1))

