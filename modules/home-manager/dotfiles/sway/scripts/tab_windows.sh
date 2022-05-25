#!/usr/bin/env bash

jq_cmd="recurse(.nodes[];.nodes!=null) |"

cur_ws_id="$(swaymsg -t get_workspaces | jq '.[] | select(.focused==true).id')"
jq_cmd+="select(.id==$cur_ws_id).nodes | .[] | recurse(.nodes[];.nodes!=null) | select(.nodes==[])"

windows="$(swaymsg -t get_tree | jq -r "$jq_cmd")"

echo "$windows"

windows_focused=($(echo "$windows" | jq '.focused'))
windows_id=($(echo "$windows" | jq '.id'))

echo "${windows_focused[@]}"
echo "${windows_id[@]}"

i=0
for focused in "${windows_focused[@]}"; do
	if [ "$focused" == "true" ]; then
		break
	fi
	((i++))
done
echo $i

if [[ "$1" == "back" ]]; then
	((i--))
elif [[ "$1" == "forward" ]]; then
	((i++))
fi


i=$(((i % ${#windows_focused[@]})))

id="${windows_id[$i]}"
echo "$id"
$(dirname "$0")/focus_on_id.sh "$id"

