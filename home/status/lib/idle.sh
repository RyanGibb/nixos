#!/usr/bin/env bash

idle="$(pgrep -f -a wm-idle- | grep bash | head -n1 | sed -e 's/.*wm-idle-\([A-Za-z0-9_-]*\).*/\1/')"

if [ -n "$idle" ]; then
	echo "idle $idle"
fi
