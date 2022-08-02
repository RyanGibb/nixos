#!/usr/bin/env bash

umask 077
mkdir /etc/nixos/secret
wg genkey > /etc/nixos/secret/wireguard_key
wg pubkey < /etc/nixos/secret/wireguard_key
