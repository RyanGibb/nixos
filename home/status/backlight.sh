#!/usr/bin/env bash

s="$(brightnessctl -c backlight -m)" || exit 1
echo "$(echo $s | awk -F, '{print "☾ " substr($4, 0, length($4)-1)}')%"

