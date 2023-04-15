#!/usr/bin/env bash

set -o pipefail

mac_addr="$(\
	nmcli -f BSSID,IN-USE,SSID,CHAN,RATE,SIGNAL,BARS,SECURITY dev wifi list\
	| tail -n +2\
	| wofi -d "Select network:"\
	| awk '{print $1}'
)" || exit

nmcli dev wifi connect "$mac_addr"
