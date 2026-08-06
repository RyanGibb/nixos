#!/usr/bin/env bash

pkill -x swayidle

swayidle -w\
	lock '@locker@'\
	timeout 120 "notify-send 'going to sleep soon!' -t 3000"\
	timeout 180 'wmdpms off'\
		resume 'wmdpms on'\
	before-sleep 'playerctl -a pause; loginctl lock-session'

