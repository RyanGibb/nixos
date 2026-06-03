#!/usr/bin/env bash

# Apply a kanshi profile's default swayidle mode, but only when the active
# profile actually *changes*. kanshi re-runs a profile's `exec` every time the
# profile is (re-)applied, and a monitor going to sleep (`output * dpms off`)
# can drop its connection, causing kanshi to re-apply the same profile. Without
# this guard that re-apply clobbers whatever idle mode was set manually via the
# sway idle-mode bindings. By skipping when the profile is unchanged, manual
# binding choices persist until the set of outputs genuinely changes.

profile="$1"
script="$2"

state="${XDG_RUNTIME_DIR:-/tmp}/kanshi_profile"

if [ "$(cat "$state" 2>/dev/null)" = "$profile" ]; then
	exit 0
fi
echo "$profile" >"$state"

exec "$script"
