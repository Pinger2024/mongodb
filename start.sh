#!/bin/bash

# Start SSH in the background
/usr/sbin/sshd -D &

# Start MongoDB in the foreground
/usr/bin/mongod --config /etc/mongod.conf