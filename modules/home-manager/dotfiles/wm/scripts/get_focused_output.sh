#!/usr/bin/env bash

@wmmsg@ -t get_tree | jq -r '.nodes[] | select([recurse(.nodes[]?, .floating_nodes[]?) | .focused] | any) | .name'
