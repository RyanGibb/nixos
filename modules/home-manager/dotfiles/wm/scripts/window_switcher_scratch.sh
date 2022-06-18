#!/usr/bin/env bash

windows=$(\
	@wmmsg@ -t get_tree |\
        jq -r '
                recurse(.nodes[], .floating_nodes[];.nodes!=null)
                | select(.name=="__i3_scratch")
                | recurse(.nodes[], .floating_nodes[];.nodes!=null)
                | select((.type=="con" or .type=="floating_con") and .name!=null)
                | "\(.id? | tostring | (" " * (3 - length)) + .) \(.app_id? // .window_properties.class?) - \(.name?)"
        '
)

selected=$(echo "$windows" | @dmenu@ "Select window:" | awk '{print $1}')

@wmmsg@ "[con_id="$selected"] focus"
