#!/usr/bin/env bash

prev="$(grep 'cpu ' /proc/stat)"
sleep 0.1
cur="$(grep 'cpu ' /proc/stat)"
awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf " %.1f%%\n", ($2+$4-u1) * 100 / (t-t1) "%"; }' <(echo $cur) <(echo $prev)
