#!/usr/bin/env sh

capacity=$1
status=$2

if [ "$status" = Discharging -a "$capacity" -lt 5 ]; then
	logger "Critical battery threshold"
	systemctl hibernate
elif [ "$status" = Discharging -a "$capacity" -lt 10 ]; then
	notify-send "warning: battery at $capacity%"
fi

pkill -RTMIN+2 i3blocks
