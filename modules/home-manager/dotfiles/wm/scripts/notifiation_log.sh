#!/bin/bash

# https://askubuntu.com/questions/770218/how-can-i-log-all-notify-send-actions

logfile=$1

dbus-monitor "interface='org.freedesktop.Notifications'" |\
	grep --line-buffered "string" |\
	grep --line-buffered -e method -e ":" -e '""' -e urgency -e notify -v |\
	grep --line-buffered '.*(?=string)|(?<=string).*' -oPi |\
	grep --line-buffered -v '^\s*$' |\
	xargs -I '{}' \
	printf "---$( date )---\n"{}"\n" >> $logfile

