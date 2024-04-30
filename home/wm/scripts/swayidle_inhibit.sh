#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock '@locker@'\
	before-sleep 'playerctl -a pause; loginctl lock-session'\
	&> ~/.swayidle_log

