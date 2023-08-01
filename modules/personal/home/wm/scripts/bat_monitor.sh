#!/usr/bin/env sh

while :
do
	echo "$(date -Ins) $(acpi -b)"\
		| tee -a ~/.bat_hist\
		| awk -F'[,:%]' '{print $6; print $7}' | {
		read -r status
		read -r capacity

		#if [ "$status" = Charging -o "$status" = Full ]; then
		#	~/.config/sway/scripts/swayidle_lock.sh
		#fi

		if [ "$status" = Discharging -a "$capacity" -lt 5 ]; then
			logger "Critical battery threshold"
			systemctl hibernate
		elif [ "$status" = Discharging -a "$capacity" -lt 10 ]; then
			notify-send "warning: battery at $capacity%"
		fi
	}
	sleep 60
done

