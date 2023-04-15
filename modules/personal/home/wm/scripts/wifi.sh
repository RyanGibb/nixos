#!/usr/bin/env bash

mac_addr="$(\
	nmcli -f BSSID,IN-USE,SSID,CHAN,RATE,SIGNAL,BARS,SECURITY dev wifi list\
	| tail -n +2\
	| wofi -d "Select network:"\
	| awk '{print $1}'
)"

nmcli dev wifi connect "$mac_addr"
