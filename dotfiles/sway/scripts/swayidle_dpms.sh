#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock 'swaylock -f -i ~/pictures/wallpapers/default'\
	timeout 120 "notify-send 'going to sleep soon!' -t 3000"\
	timeout 180 'swaymsg "output * dpms off"'\
		resume 'swaymsg "output * dpms on"'\
	before-sleep 'playterctl -a pause; loginctl lock-session'\
	&> ~/.swayidle_log

pkill -RTMIN+8 waybar
