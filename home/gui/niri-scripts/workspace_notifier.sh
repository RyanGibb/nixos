#!/usr/bin/env bash
# Fire `st workspace` whenever the focused niri workspace label changes.
# WorkspacesChanged also covers reorders and the renumbering that follows a
# workspace being added or removed; comparing the label suppresses the rest.
niri msg -j event-stream | jq --unbuffered -rc '
    select(has("WorkspaceActivated") or has("WorkspacesChanged")) | "tick"
' | {
    last=""
    while read -r _; do
        cur="$(wm-ws-name)"
        [ "$cur" = "$last" ] && continue
        last="$cur"
        st workspace -t 500
    done
}
