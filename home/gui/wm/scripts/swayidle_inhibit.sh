#!/usr/bin/env bash

pkill -x swayidle

swayidle -w\
	lock '@locker@'\
	before-sleep 'playerctl -a pause; loginctl lock-session'

