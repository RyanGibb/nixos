#!/usr/bin/env bash

dir=/etc/nixos/secret
file=wireguard_key

umask 077
mkdir /etc/nixos/secret
chmod 700 "$dir"

wg genkey > "$dir/$file"
wg pubkey < "$dir/$file"

