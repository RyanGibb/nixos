#!/usr/bin/env bash

mac_addr="$(nmcli con show | tail -n +2 | wofi -d -i -p "Select network:" | awk '{print $(NF-2)}')"

nmcli con up "$mac_addr"
