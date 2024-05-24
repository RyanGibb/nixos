#!/usr/bin/env bash

if [ $XDG_SESSION_TYPE = "wayland" ]; then
	echo "workspace $(~/.config/sway/scripts/get_cur_ws_name.sh)"
elif [ $XDG_SESSION_TYPE = "x11" ]; then
	echo "workspace $(~/.config/i3/scripts/get_cur_ws_name.sh)"
fi

