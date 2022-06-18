#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock '@locker@ -f -i ~/pictures/wallpapers/default'\
	timeout 120 "notify-send 'going to sleep soon!' -t 3000"\
	timeout 180 '@wmmsg@ "output * dpms off"'\
		resume '@wmmsg@ "output * dpms on"'\
	before-sleep 'playterctl -a pause; loginctl lock-session'\
	&> ~/.swayidle_log

pkill -RTMIN+11 i3blocks
