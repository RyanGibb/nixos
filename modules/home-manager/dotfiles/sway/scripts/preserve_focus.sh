#!/usr/bin/env bash

ID="$($(dirname "$0")/get_cur_focus_id.sh)"
$1
$(dirname "$0")/focus_on_id.sh "$ID"
