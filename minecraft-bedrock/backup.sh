#!/bin/bash

timestamp=$(date -Iseconds)
serverlogfile="/log.txt"
lockfile="/lock"

# Test if our lock file is in place. We don't want concurrent backups running:
if [ -f $lockfile ]; then
    exit 1
fi

# Create a lockfile for this backup:
touch $lockfile

# Notify server that a backup is starting:
screen -x bedrock -X stuff 'say §6Starting backup...\n'

# Pause modifications to the world:
screen -x bedrock -X stuff 'save hold\n'

# Wait for hold confirmation:
finished=""

while [[ $finished != *"Data saved."* ]]; do
    screen -x bedrock -X stuff 'say Waiting for world lock...\n'
    sleep 5s
    screen -s bedrock -X stuff 'save query\n'
    finished=$(tail -n 4 $serverlogfile)
done

# Let users know the world is locked:
screen -x bedrock -X stuff 'say §cThe world is temporarily locked while the backup is captured!\n'

# Copy World:
rsync -rvz "/data/worlds" "/backups/worlds-$timestamp"

# Unlink + re-link latest copy for easy reference:
rm -f "/backups/latest"
ln -s "/backups/worlds-$timestamp" "/backups/latest"

# Unlock:
screen -x bedrock -X stuff 'save resume\n'

# Clean up lockfile:
rm -f $lockfile

# Notify server of completed backup:
screen -x bedrock -X stuff 'say §aBackup complete!\n'