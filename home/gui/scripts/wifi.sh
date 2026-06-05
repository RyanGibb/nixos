#!/usr/bin/env bash

set -o pipefail

ssid="$(\
	nmcli -g IN-USE,SSID,SIGNAL,BARS,SECURITY dev wifi list\
	| awk -F: '$2 != "" && !seen[$2]++ {printf "%s %s %s %s\t%s\n", $1, $4, $3, $5, $2}'\
	| wofi -d "Select network:"\
	| cut -f2-
)" || exit

nmcli dev wifi connect "$ssid"
