#!/usr/bin/env bash

sinks=($(pactl list short sinks | cut -f 2))

default_sink=$(pactl info | sed -En 's/Default Sink: (.*)/\1/p')

for i in "${!sinks[@]}"; do
	if [[ "${sinks[$i]}" = "${default_sink}" ]]; then
		break
	fi
done

if [[ "$1" == "back" ]]; then
	j=-1
else
	j=1
fi

prev_i=$i

# find first sink succesfully set as default
while [[ "$(pactl info | sed -En 's/Default Sink: (.*)/\1/p')" == "$default_sink" ]]; do
	i=$(((i+j)%${#sinks[@]}))
	pactl set-default-sink "${sinks[$i]}"
	#  break if no other sink
	if [ $prev_i -eq $i ]; then
		break
	fi
	echo $i
done

