#!/usr/bin/env bash

bt_cmd=${1:-connect}

devices="$(echo 'devices' | bluetoothctl | grep '^Device' | sed "s/^[^ ]* //")"

awk -v bt_cmd="$bt_cmd" '{printf("power on\n%s %s\n", bt_cmd, $1)}' < <(\
	echo "$devices"	| @dmenu@ "Select device to $bt_cmd:"
) > >(bluetoothctl)

