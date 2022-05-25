#!/usr/bin/env bash
PROMPT='Move to workspace: '
ID="$($(dirname "$0")/get_cur_focus_id.sh)"
NAME=$($(dirname "$0")/select_ws.sh "$PROMPT")
$(dirname "$0")/focus_on_id.sh "$ID"
i3-msg move container to workspace \"$NAME\"