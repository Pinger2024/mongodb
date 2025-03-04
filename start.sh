#!/bin/bash

# Debug: Show initial state
echo "Starting deployment..."
ps aux | grep sshd || echo "No initial sshd processes."

# Start SSH server using service command
echo "Starting SSH server..."
service ssh start

# Check if sshd is running
if ps aux | grep -q "[s]shd"; then
    echo "SSH server is running."
else
    echo "SSH server failed to start."
    # Run sshd in debug mode to capture errors
    /usr/sbin/sshd -d -e
    exit 1
fi

# Start MongoDB in the foreground
echo "Starting MongoDB..."
mongod --config /etc/mongod.conf