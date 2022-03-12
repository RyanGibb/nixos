#!/usr/bin/env bash

upower --dump | grep keyboard -A 7 | grep percentage | awk '{print $2}'
