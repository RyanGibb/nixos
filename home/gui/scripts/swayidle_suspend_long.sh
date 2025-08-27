#!/usr/bin/env bash

pkill -x swayidle

swayidle -w\
	lock '@locker@'\
	timeout 300 "notify-send 'going to sleep soon!' -t 300000"\
	timeout 3600 '@wmmsg@ "output * dpms off"'\
		resume '@wmmsg@ "output * dpms on"'\
	timeout 3900 'loginctl lock-session'\
	timeout 7200 'systemctl suspend-then-hibernate'\
	before-sleep 'playerctl -a pause; loginctl lock-session'
