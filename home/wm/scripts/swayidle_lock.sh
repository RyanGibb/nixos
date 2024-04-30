#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock '@locker@'\
	timeout 120 "notify-send 'going to sleep soon!' -t 3000"\
	timeout 180 '@wmmsg@ "output * dpms off"'\
		resume '@wmmsg@ "output * dpms on"'\
	timeout 240 'loginctl lock-session'\
	before-sleep 'playerctl -a pause; loginctl lock-session'\
	&> ~/.swayidle_log

