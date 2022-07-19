#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock '@locker@'\
	before-sleep 'playterctl -a pause; loginctl lock-session'\
	&> ~/.swayidle_log

pkill -RTMIN+11 i3blocks
