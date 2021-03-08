#!/bin/bash

shopt -s extglob

for pid in $(cd /proc && echo +([0-9])); do 
    if [ -f /proc/"$pid"/cmdline ]; then
        grep -q "bedrock_server" /proc/"$pid"/cmdline; [ $? -eq 0 ] && echo -n "$pid"
    fi 
done
