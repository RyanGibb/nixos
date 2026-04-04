#!/usr/bin/env bash
# Freezes the screen, then does two-point region selection, then captures.
# Tooltips/popups stay visible during selection. Outputs PNG to stdout.
set -o pipefail

SCRIPT_DIR="$(dirname "$0")"

wayfreeze &
pid=$!
trap 'kill $pid 2>/dev/null' EXIT
sleep 0.1

grim -g "$("$SCRIPT_DIR/slurp_point.sh")" -
