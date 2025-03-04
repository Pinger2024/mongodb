#!/bin/bash

# Debug: Show initial state
echo "Starting deployment..."

# Start SSH server directly with logging
echo "Starting SSH server..."
/usr/sbin/sshd -e &

# Wait briefly and check if sshd is running
sleep 2
if ps aux | grep -q "[s]shd"; then
    echo "SSH server is running."
else
    echo "SSH server failed to start - running in foreground for debug..."
    /usr/sbin/sshd -d -e
    exit 1
fi

# Start MongoDB in the foreground
echo "Starting MongoDB..."
mongod --config /etc/mongod.conf