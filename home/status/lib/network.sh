#!/usr/bin/env bash

INTERFACES=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status)

SSID=$(echo "$INTERFACES" | awk -F : '/wifi:connected/ {print $4}')

# if it exists, display wireless SSID with SIGNAL strenght
if [ -n "$SSID" ]; then
	echo " $SSID"
# otherwise, if ethernet connection exists display that
elif [ -n "$(echo "$INTERFACES" | awk -F : '/ethernet:connected/ {print $4}')" ]; then
	echo "󰈀 "
# if wifi is enabled, display unlink
elif [ "$(nmcli r wifi)" == "enabled" ]; then
	echo " "
# otherwise, display x
else
	echo "x"
fi
