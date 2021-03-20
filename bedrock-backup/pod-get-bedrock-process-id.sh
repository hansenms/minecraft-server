#!/bin/bash

shopt -s extglob

for pid in $(cd /proc && echo +([0-9])); do 
    if [ -f "/proc/${pid}/cmdline" ]; then
        if grep -q "bedrock_server" "/proc/${pid}/cmdline"; then echo -n "${pid}"; fi
    fi 
done
