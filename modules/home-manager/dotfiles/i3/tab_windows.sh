#!/usr/bin/env bash

jq_cmd="recurse(.nodes[];.nodes!=null) |"

if [[ "$1" != "all_ws" ]]; then
	cur_ws_id="$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).id')"
	# filter by current workspace
	jq_cmd+="select(.id==$cur_ws_id).nodes | .[] | recurse(.nodes[];.nodes!=null) |"
fi

jq_cmd+="select(
	.layout!=\"dockarea\" and
	.window_properties.class!=\"i3bar\" and
	.window!=null
)"

windows="$(i3-msg -t get_tree | jq -r "$jq_cmd")"

windows_focused=($(echo "$windows" | jq '.focused'))
windows_id=($(echo "$windows" | jq '.id'))

i=0
for focused in "${windows_focused[@]}"; do
	if [ "$focused" == "true" ]; then
		break
	fi
	((i++))
done

if [[ "$2" == "back" ]]; then
	((i--))
elif [[ "$2" == "forward" ]]; then
	((i++))
fi


i=$(((i % ${#windows_focused[@]})))

id="${windows_id[$i]}"
echo "$id"
$(dirname "$0")/focus_on_id.sh "$id"
