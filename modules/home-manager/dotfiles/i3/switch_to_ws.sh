#!/usr/bin/env bash
PROMPT='Switch to workspace: '
NAME=$($(dirname "$0")/select_ws.sh "$PROMPT")
i3-msg workspace \"$NAME\"