#!/usr/bin/env bash

networks="$(nmcli -f BSSID,IN-USE,SSID,CHAN,RATE,SIGNAL,BARS,SECURITY dev wifi list | tail -n +2)"

mac_addr="$(echo "$networks" | wofi -d -i -p "Select network:" | awk '{print $1}')"

nmcli dev wifi connect "$mac_addr"

