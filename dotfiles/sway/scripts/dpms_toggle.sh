#!/bin/bash

lockfile=/tmp/screen-off-lock

if [ -f $lockfile ];
then
    rm "$lockfile"
	swaymsg "output * enable"
	swaymsg "output * dpms on"
else
    touch "$lockfile"
	swaymsg "output * dpms off"
fi

