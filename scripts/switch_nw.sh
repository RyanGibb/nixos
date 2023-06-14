#!/usr/bin/env sh

nmcli con up "$1"

sleep 60

systemctl restart ddclient
