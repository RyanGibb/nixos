#!/usr/bin/env bash
# Fire `st workspace` whenever the focused niri workspace changes.
niri msg -j event-stream | jq --unbuffered -rc '
    .WorkspaceActivated // empty
' | while read -r _; do
    st workspace -t 500
done
