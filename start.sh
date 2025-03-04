#!/bin/bash

# Start the SSH server in the background
service ssh start

# Start MongoDB in the foreground to keep the container running
mongod --config /etc/mongod.conf