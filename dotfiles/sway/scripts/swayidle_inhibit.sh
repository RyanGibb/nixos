#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock 'swaylock -f -i ~/pictures/wallpapers/default'\
	before-sleep 'playterctl -a pause; loginctl lock-session'\
	&> ~/.swayidle_log

pkill -RTMIN+8 waybar
