#!/usr/bin/env bash

if ! stat=$(playerctl status 2> /dev/null); then exit 0; fi
if ! title=$(playerctl metadata title 2> /dev/null); then exit 0; fi
if ! artist=$(playerctl metadata artist 2> /dev/null); then exit 0; fi

if [ "$stat" = "Playing" ]; then
	stat="󰐊"
elif [ "$stat" = "Paused" ]; then
	stat=""
fi

echo "$stat $title | $artist"