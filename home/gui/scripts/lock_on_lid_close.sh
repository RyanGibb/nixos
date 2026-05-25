#!/usr/bin/env bash

# lock if only monitor
if [ "$(@wmmsg@ -t get_outputs | grep -c '"type": "output"')" = "1" ]; then
	loginctl lock-session
fi
