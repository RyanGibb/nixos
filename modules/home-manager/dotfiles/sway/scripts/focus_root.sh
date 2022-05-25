#!/usr/bin/env bash

ID=0

while [[ "$ID" != "$PREV_ID" ]]; do
	PREV_ID=$ID
	# this is not very efficient...
	ID=$($(dirname "$0")/get_cur_focus_id.sh)
	echo $ID
	swaymsg focus parent
done

