#!/bin/bash

# Debug: Show initial state
echo "Starting deployment..."

# Start SSH server in the background with debug logging
echo "Starting SSH server..."
/usr/sbin/sshd -e 2>&1 | tee /var/log/sshd.log &

# Wait briefly to ensure sshd binds to port 22
sleep 2

# Check if sshd is running
if ps aux | grep -q "[s]shd"; then
    echo "SSH server is running."
else
    echo "SSH server failed to start."
    cat /var/log/sshd.log
    exit 1
fi

# Start MongoDB in the foreground to keep container running
echo "Starting MongoDB..."
exec mongod --config /etc/mongod.conf