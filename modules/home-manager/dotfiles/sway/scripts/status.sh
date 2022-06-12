#!/usr/bin/env bash

cd "$(dirname $0)"

i3status | while :
do
        read line
        echo " $(./idle_status.sh) | ☾ $(./brightness_status.sh) | $line" || exit 1
done
