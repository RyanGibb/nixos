#!/usr/bin/env bash

stat=`playerctl status 2> /dev/null`
if [ $? -ne 0 ]; then exit 0; fi
title=`playerctl metadata title 2> /dev/null`
if [ $? -ne 0 ]; then exit 0; fi
artist=`playerctl metadata artist 2> /dev/null`
if [ $? -ne 0 ]; then exit 0; fi

if [ "$stat" == "Playing" ]; then
	stat="󰐊"
elif [ "$stat" == "Paused" ]; then
	stat=""
fi

echo "$stat $title | $artist"

