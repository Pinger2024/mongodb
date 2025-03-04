#!/bin/bash

# Ensure no lingering sshd processes
pkill sshd || echo "No sshd processes to kill."

# Start SSH server with error logging
echo "Starting SSH server..."
/usr/sbin/sshd -e &
SSHD_PID=$!
echo "SSH server started with PID $SSHD_PID."

# Wait briefly to ensure sshd is up
sleep 2

# Verify sshd is running
if ps -p $SSHD_PID > /dev/null; then
    echo "SSH server is running."
else
    echo "SSH server failed to start."
    exit 1
fi

# Start MongoDB in the foreground
echo "Starting MongoDB..."
mongod --config /etc/mongod.conf