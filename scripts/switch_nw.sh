#!/bin/bash

nmcli con up "$1"

sleep 60

systemctl restart ddclient

