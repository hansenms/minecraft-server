#!/bin/bash

folder=$(dirname "$0")
cmd=$1
pid=$("$folder/pod-get-bedrock-process-id.sh")

if [[ -n "${pid}" && -f "/proc/${pid}/cmdline" ]]; then
    echo "${cmd}" > "/proc/${pid}/fd/0"
else
    echo "Error: Unable to find bedrock server process id"
    exit 1
fi
