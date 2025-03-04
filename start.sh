#!/bin/bash
set -e

echo "Starting deployment..."

# Start SSH server in normal (daemon) mode; run it in the background
echo "Starting SSH server..."
/usr/sbin/sshd -D &

# Wait briefly to ensure sshd binds to port 22
sleep 2

# Verify that sshd is running
if ps aux | grep -q "[s]shd"; then
    echo "SSH server is running."
else
    echo "SSH server failed to start."
    exit 1
fi

# Start MongoDB in the foreground to keep the container alive
echo "Starting MongoDB..."
exec mongod --config /etc/mongod.conf
