#!/usr/bin/env bash

if [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
	fullscreen=$(niri msg --json focused-window | jq -r '.is_fullscreen // false')
else
	fullscreen=$(swaymsg -t get_tree | jq '.. | select(.type? == "con" and .focused == true) | .fullscreen_mode')
fi

case "$fullscreen" in
	0|false|"") echo "Not Fullscreen" ;;
	*)          echo "Fullscreen" ;;
esac
