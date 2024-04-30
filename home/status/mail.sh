#!/usr/bin/env bash

shopt -s extglob

NEW=`find ~/mail/@(ryan@freumh.org|ryangibb321@gmail.com|ryan.gibb@cl.cam.ac.uk)/Inbox/new -type f | wc -l`

if [ "$NEW" != "0" ]; then
  echo "<b>new mail</b> ${NEW}"
fi
