#!/usr/bin/env bash
# Freezes the screen, then does two-point region selection, then captures.
# Tooltips/popups stay visible during selection. Outputs PNG to stdout.
set -o pipefail

wayfreeze &
pid=$!
trap 'kill $pid 2>/dev/null' EXIT
sleep 0.1

point="$(slurp -p | cut -d \  -f 1)" || exit
IFS=',' read -ra coord <<< "$point"
x1="${coord[0]}"
y1="${coord[1]}"

point="$(slurp -p | cut -d \  -f 1)" || exit
IFS=',' read -ra coord <<< "$point"
x2="${coord[0]}"
y2="${coord[1]}"

if (($x1 < $x2)); then w=$(($x2 - $x1)); x=$x1; else w=$(($x1 - $x2)); x=$x2; fi
if (($y1 < $y2)); then h=$(($y2 - $y1)); y=$y1; else h=$(($y1 - $y2)); y=$y2; fi

grim -g "$x,$y ${w}x${h}" -
