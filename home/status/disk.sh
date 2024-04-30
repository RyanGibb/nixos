#!/usr/bin/env bash

df -h -P -l / | awk 'NR == 2 {printf " %s/%s\n", $4, $2; exit}'
