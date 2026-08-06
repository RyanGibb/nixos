#!/usr/bin/env bash

pkill -x swayidle

swayidle -w\
	lock '@locker@'\
	timeout 3300 "notify-send 'going to sleep soon!' -t 300000"\
	timeout 3600 'wmdpms off'\
		resume 'wmdpms enable; wmdpms on'\
	timeout 7200 'systemctl suspend'\
	before-sleep 'playerctl -a pause'
