#!/bin/bash

rm -f bedrock_server *.so 2> /dev/null
unzip -n -q /tmp/bds.zip # Don't overwrite
chmod +x bedrock_server

export LD_LIBRARY_PATH=.
screen -S bedrock /opt/bedrock/run_bedrock.sh

# ./bedrock_server
