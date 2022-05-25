#!/usr/bin/env bash

MAX_WIDTH=24
INCREMENT=1

NUM_PLAYERS=1

while : ; do
	players=($(playerctl -l 2> /dev/null | head -n $NUM_PLAYERS))
	if [[ "$players" != "$prev_players" ]]; then
		indices=("${players[@]/*/1}")
		prev_players="$players"
	fi
	max_players_index="$(((${#players[@]}-1)))"
	string=""
	for (( i=$max_players_index ; i>=0 ; i-- )); do
		player="${players[$i]}"
		title="$(playerctl --player="$player" metadata title)"
		if [[ -z "$title" ]]; then
			continue
		fi
		player_string="$title"

		artist="$(playerctl --player="$player" metadata artist)"
		if ! [[ -z "$artist" ]]; then
			player_string+=" - $artist"
		fi

		len="${#player_string}"

		if [[ $len -gt $MAX_WIDTH ]]; then
			player_string+=" | "
			len="${#player_string}"
			start="${indices[$i]}"
			end=$((($start + $MAX_WIDTH)))
			new_player_string="${player_string:$start:$MAX_WIDTH}"
			if [[ $end -ge $len ]]; then
				new_player_string+="${player_string:0:$MAX_WIDTH-$len+$start}"
			fi
			player_string="$new_player_string"
			indices[$i]="$((( (indices[$i]+$INCREMENT) % ($len) )))"
		fi

		if [[ "$i" != "$max_players_index" ]]; then
			string+="  "
		fi
		if [[ $player = *"spotify"* ]]; then
			string+=""
		fi
		if [[ $player = *"firefox"* ]]; then
			string+=""
		fi
		string+="$player_string"
	done
	echo "$string"
	sleep 1
done
