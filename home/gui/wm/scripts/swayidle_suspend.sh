#!/usr/bin/env bash

pkill -x swayidle

swayidle -w\
	lock '@locker@'\
	timeout 120 "notify-send 'going to sleep soon!' -t 3000"\
	timeout 180 '@wmmsg@ "output * dpms off"'\
		resume '@wmmsg@ "output * dpms on"'\
	timeout 240 'loginctl lock-session'\
	timeout 300 'systemctl suspend-then-hibernate'\
	before-sleep 'playerctl -a pause; loginctl lock-session'\
	after-resume 'pkill -x swaylock; timewall set; loginctl lock-session' # for timewall

