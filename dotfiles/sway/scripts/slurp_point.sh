#!/usr/bin/env bash

set -o pipefail

point="$(slurp -p | cut -d \  -f 1)" || exit

IFS=',' read -ra coord <<< "$point"
x1="${coord[0]}"
y1="${coord[1]}"

point="$(slurp -p | cut -d \  -f 1)" || exit

IFS=',' read -ra coord <<< "$point"
x2="${coord[0]}"
y2="${coord[1]}"

if (($x1 < $x2)); then
	x_size=$(($x2 - $x1))
	x=$x1
else
	x_size=$(($x1 - $x2))
	x=$x2
fi

if (($y1 < $y2)); then
	y_size=$(($y2 - $y1))
	y=$y1
else
	y_size=$(($y1 - $y2))
	y=$y2
fi

echo $x,$y ${x_size}x$y_size

