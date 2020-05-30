#!/bin/bash

rm -f bedrock_server *.so 2> /dev/null
unzip -n -q /tmp/bds.zip # Don't overwrite
chmod +x bedrock_server

# Set configuration values provided in environment variables
CONFIG="server.properties"
function set_config(){
    sed -i "s/^\($1\s*=\s*\).*\$/\1$2/" $CONFIG
}

if [ ! -z "${SERVER_NAME}" ]; then
    set_config "server-name" $SERVER_NAME
fi

if [ ! -z "${MAX_PLAYERS}" ]; then
    set_config "max-players" $MAX_PLAYERS
fi

if [ ! -z "${ONLINE_MODE}" ]; then
set_config "online-mode" $ONLINE_MODE
fi

if [ ! -z "${DIFFICULTY}" ]; then
set_config "difficulty" $DIFFICULTY
fi

if [ ! -z "${GAMEMODE}" ]; then
set_config "gamemode" $GAMEMODE
fi

export LD_LIBRARY_PATH=.
screen -S bedrock /opt/bedrock/run_bedrock.sh
