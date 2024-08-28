#!/usr/bin/env bash

stat=`playerctl status`
if [ $? -ne 0 ]; then exit 0; fi
title=`playerctl metadata title`
if [ $? -ne 0 ]; then exit 0; fi
artist=`playerctl metadata artist`
if [ $? -ne 0 ]; then exit 0; fi

if [ "$stat" == "Playing" ]; then
	stat="󰐊"
elif [ "$stat" == "Paused" ]; then
	stat=""
fi

echo "$stat $title | $artist"

