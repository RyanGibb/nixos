#!/usr/bin/env bash

INFOS=()

DATE=`date "+%a <b>%Y-%m-%d</b> %I:%M:%S%p"`
INFOS+=("$DATE")

MAIL="`$(dirname "$0")/mail.sh`"
if [ "$MAIL" != "" ]; then INFOS+=("$MAIL"); fi
IDLE="`$(dirname "$0")/idle.sh`"
if [ "$IDLE" != "" ]; then INFOS+=("$IDLE"); fi
INFOS+=("`$(dirname "$0")/disk.sh`");
INFOS+=("`$(dirname "$0")/cpu.sh`");
INFOS+=("`$(dirname "$0")/temperature.sh`");
INFOS+=("`$(dirname "$0")/load_average.sh`");
INFOS+=("`$(dirname "$0")/memory.sh`");
INFOS+=("`$(dirname "$0")/network.sh`");
BACKLIGHT="`$(dirname "$0")/backlight.sh`"
if [ "$BACKLIGHT" != "" ]; then INFOS+=("$BACKLIGHT"); fi
PULSE="`$(dirname "$0")/pulse.sh`"
if [ "$PULSE" != "" ]; then INFOS+=("$PULSE"); fi
BATTERY="`$(dirname "$0")/battery.sh`"
if [ "$BATTERY" != "" ]; then INFOS+=("$BATTERY"); fi

IFS=$'\n'; echo "${INFOS[*]}"

dunstify -r '101010' -t 10 -u low "Status" "`IFS=$'\n'; echo "${INFOS[*]}"`"
