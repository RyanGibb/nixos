#!/usr/bin/env bash

idle="$(pgrep -f -a swayidle | grep bash | sed -e 's/\(.*\)swayidle_\(.*\)\.sh/\2/')"

if [ -n "$idle" ]; then
	echo "idle $idle"
fi
