#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock '@locker@ -f -i ~/pictures/wallpapers/default'\
	timeout 120 "notify-send 'going to lock soon!' -t 3000"\
	timeout 240 'loginctl lock-session'\
	before-sleep 'playerctl -a pause; loginctl lock-session'\
	&> ~/.swayidle_log

pkill -RTMIN+11 i3blocks
