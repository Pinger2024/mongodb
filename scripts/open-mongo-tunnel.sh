#!/usr/bin/env bash
set -euo pipefail

# Open an SSH tunnel from localhost to a private MongoDB running on Render.
#
# Usage:
#   scripts/open-mongo-tunnel.sh [-p local_port] [-r region_host] [-i identity_file] [-R remote_host:remote_port] [-F] [-v]
#                                <ssh_username>
#
# Examples:
#   scripts/open-mongo-tunnel.sh srv-xxxx@ssh.oregon.render.com   # (deprecated style)
#   scripts/open-mongo-tunnel.sh -p 27018 srv-xxxx               # preferred; region via -r
#   scripts/open-mongo-tunnel.sh -r ssh.oregon.render.com srv-xxxx
#   scripts/open-mongo-tunnel.sh -i ~/.ssh/id_ed25519 -r ssh.oregon.render.com srv-xxxx
#   scripts/open-mongo-tunnel.sh -F -r ssh.oregon.render.com srv-xxxx  # run in foreground
#
# Notes:
# - <ssh_username> is the service SSH Username shown in Render → Service → Settings → SSH.
# - region_host defaults to ssh.oregon.render.com; override with -r for other regions.
# - Requires your public key to be added to Render Account Settings → SSH Keys.

usage() {
  cat >&2 <<EOF
Open an SSH tunnel to a Render Mongo service.

Usage: $0 [-p local_port] [-r region_host] [-i identity_file] [-R remote_host:remote_port] [-F] [-v] <ssh_username>

Options:
  -p  Local port to listen on (default: 27018)
  -r  Render SSH bastion host (default: ssh.oregon.render.com)
  -i  SSH identity file (private key). If omitted, ssh defaults are used
  -R  Remote host:port inside container (default: 127.0.0.1:27017)
  -F  Run in foreground (default: background with -fN)
  -v  Verbose SSH output

Example:
  $0 -r ssh.oregon.render.com -p 27018 srv-xxxxxxxxxxxxxxxxxxxx
Then connect Compass to: mongodb://localhost:27018/?directConnection=true&tls=false
EOF
}

local_port=27018
region_host="ssh.oregon.render.com"
identity=""
remote_host="127.0.0.1"
remote_port="27017"
foreground=false
ssh_verbose=""

while getopts ":p:r:i:R:Fvh" opt; do
  case "$opt" in
    p) local_port="$OPTARG" ;;
    r) region_host="$OPTARG" ;;
    i) identity="$OPTARG" ;;
    R)
      case "$OPTARG" in
        *:*) remote_host="${OPTARG%%:*}"; remote_port="${OPTARG##*:}" ;;
        *) echo "-R expects host:port" >&2; exit 1 ;;
      esac
      ;;
    F) foreground=true ;;
    v) ssh_verbose="-vv" ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument" >&2; usage; exit 1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 1 ;;
  esac
done
shift $((OPTIND-1))

if [[ $# -lt 1 ]]; then
  echo "Missing <ssh_username> (Render service SSH Username)" >&2
  usage
  exit 1
fi

ssh_user="$1"

if ! command -v ssh >/dev/null 2>&1; then
  echo "ssh not found on PATH. Install OpenSSH client first." >&2
  exit 1
fi

ssh_args=("-o" "IdentitiesOnly=yes" "-o" "ExitOnForwardFailure=yes" "-o" "ServerAliveInterval=60" "-o" "ServerAliveCountMax=3")
[[ -n "$ssh_verbose" ]] && ssh_args+=("$ssh_verbose")

if [[ -n "$identity" ]]; then
  if [[ ! -f "$identity" ]]; then
    echo "Identity file not found: $identity" >&2
    exit 1
  fi
  ssh_args+=("-i" "$identity")
fi

if [[ "$foreground" == true ]]; then
  mode=("-N")
else
  mode=("-fN")
fi

echo "Opening tunnel: localhost:$local_port -> $remote_host:$remote_port via $ssh_user@$region_host" >&2
set -x
ssh "${mode[@]}" -L "$local_port:$remote_host:$remote_port" "${ssh_args[@]}" "$ssh_user@$region_host"
set +x

# Verify local port
if command -v nc >/dev/null 2>&1; then
  if nc -z localhost "$local_port" >/dev/null 2>&1; then
    echo "Tunnel up on localhost:$local_port"
  else
    echo "Tunnel command returned, but localhost:$local_port is not reachable." >&2
    exit 1
  fi
else
  echo "Tunnel attempted. If nc is not installed, verify with: mongosh \"mongodb://localhost:$local_port/?directConnection=true&tls=false\"" >&2
fi

echo "Connect Compass to: mongodb://localhost:$local_port/?directConnection=true&tls=false"

