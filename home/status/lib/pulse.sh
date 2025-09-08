#!/usr/bin/env bash

mapfile -t sink_ids < <(pactl list short sinks | cut -f 1)
mapfile -t sinks < <(pactl list short sinks | cut -f 2)

default_sink=$(pactl info | sed -En 's/Default Sink: (.*)/\1/p')
default_source=$(pactl info | sed -En 's/Default Source: (.*)/\1/p')

for i in "${!sinks[@]}"; do
	if [[ "${sinks[$i]}" = "${default_sink}" ]]; then
		break
	fi
done

deets="$(pactl list sinks | grep -A14 "#${sink_ids[$i]}")"
vol="$(echo "$deets" | grep "Volume" | head -1 | awk '{print $5}')"
mute="$(echo "$deets" | grep "Mute: yes")"
desc="$(echo "$deets" | grep "Description:" | sed 's/.*Description: //')"

if [ -n "$mute" ]; then
	label=""
else
	label=""
fi

mic_mute="$(pactl list sources | grep -A14 "$default_source" | grep "Mute: no")"
if [ -z "$mic_mute" ]; then
	mic=""
else
	mic=""
fi

echo "$label $vol $mic $desc"

