#!/usr/bin/env bash

lockfile=/tmp/screen-off-lock

if [ -f $lockfile ];
then
    rm "$lockfile"
	@wmmsg@ "output * enable"
	@wmmsg@ "output * dpms on"
else
    touch "$lockfile"
	@wmmsg@ "output * dpms off"
fi

