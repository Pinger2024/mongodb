#!/usr/bin/env bash
set -euo pipefail

# Verify a local MongoDB SSH tunnel by checking the port and optional ping.
#
# Usage:
#   scripts/verify-tunnel.sh [-p local_port] [--ping]

port=27018
do_ping=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port)
      port="$2"; shift 2 ;;
    --ping)
      do_ping=true; shift ;;
    -h|--help)
      echo "Usage: $0 [-p local_port] [--ping]"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

echo "Checking localhost:$port ..."
if command -v nc >/dev/null 2>&1; then
  if nc -zv localhost "$port" >/dev/null 2>&1; then
    echo "Port is open."
  else
    echo "Port check failed. Is the tunnel running?" >&2
    exit 1
  fi
else
  echo "nc not available; skipping port check."
fi

if [[ "$do_ping" == true ]]; then
  if command -v mongosh >/dev/null 2>&1; then
    echo "Pinging Mongo via mongosh ..."
    if mongosh --quiet --host localhost --port "$port" --tls=false --eval 'db.runCommand({ ping: 1 })' | grep -q 'ok'; then
      echo "Mongo responded to ping. Tunnel looks good."
    else
      echo "mongosh ping failed; check Mongo status in the container." >&2
      exit 1
    fi
  else
    echo "mongosh not found; skipping ping. Install MongoDB Shell to run ping."
  fi
fi

echo "Use Compass with: mongodb://localhost:$port/?directConnection=true&tls=false"

