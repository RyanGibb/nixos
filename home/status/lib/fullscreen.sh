#!/usr/bin/env bash

fullscreen=$(swaymsg -t get_tree | jq '.. | select(.type? == "con" and .focused == true) | .fullscreen_mode')

if [ "$fullscreen" -eq 0 ]; then
    echo "Not Fullscreen"
else
    echo "Fullscreen"
fi
