#!/usr/bin/env bash

dirs=/sys/class/thermal/thermal_zone*
paste <(cat $dirs/type) <(cat $dirs/temp) | awk '/TCPU/ {printf " %2.0f°C\n", $2/1000}'
