#!/usr/bin/env bash

sink_ids=($(pactl list short sinks | cut -f 1))
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

while true; do
	i=$(((i+j)%${#sinks[@]}))
	echo $i
	if ! pactl list sinks | sed -n "/Sink #${sink_ids[$i]}/,\$p" | grep "\[Out\]" | head -n 1 | grep "not available"; then
		pactl set-default-sink "${sinks[$i]}"
		break
	fi
	#  break if no other sink
	if [ $prev_i -eq $i ]; then
		break
	fi
done

