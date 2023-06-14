#!/usr/bin/env sh

rsync -va --exclude={".cache", ".local/share/Steam/"} ~/ /run/media/ryan/external-hdd/home/
