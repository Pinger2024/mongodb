Compass via SSH Tunnel (Render)
================================

This guide lets you connect MongoDB Compass on your laptop to a private MongoDB running on Render using an SSH tunnel.

Prerequisites
- Render CLI installed and logged in: `brew install render && render login`
- Your SSH public key added in Render → Account Settings → SSH Keys
- SSH enabled on the Mongo service: Service → Settings → SSH → Enable
- SSH Username for the service (looks like `srv-...`): Service → Settings → SSH
- Region host for your service (e.g., Oregon → `ssh.oregon.render.com`)

1) Test SSH access
Run this once to confirm SSH works. Replace placeholders.

```
ssh -vvv -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes <SSH_USERNAME>@ssh.oregon.render.com
```

If it closes immediately, check:
- SSH not enabled on the service (enable it in Settings)
- Wrong username (copy it from Service → Settings → SSH)
- Wrong region host (use the one matching your service region)
- Key mismatch (ensure the public key in Render matches your private key)
- Corporate network blocks port 22 → try `-p 443`

2) Open the tunnel (helper script)
From the repo root, open a local port 27018 to forward to Mongo’s 27017 inside the service.

```
scripts/open-mongo-tunnel.sh -r ssh.oregon.render.com <SSH_USERNAME>
```

Options:
- `-p 27019` use a different local port
- `-i ~/.ssh/id_ed25519` specify identity file
- `-F` run in foreground (omit to run in background)

3) Verify locally

```
scripts/verify-tunnel.sh --ping
```

4) Connect Compass

Use this connection string in Compass:

```
mongodb://localhost:27018/?directConnection=true&tls=false
```

If you later enable Mongo auth, use:

```
mongodb://USER:PASS@localhost:27018/?authSource=admin&directConnection=true&tls=false
```

Troubleshooting
- Permission denied (publickey): Add your public key to Render, or pass `-i` with the right private key. Ensure `chmod 600 ~/.ssh/id_*`.
- Channel open failed / administratively prohibited: Account/region policy may block port forwarding. Use Compass’ built‑in SSH Tunnel settings or consider a sidecar admin UI (e.g., Mongo Express) inside Render.
- Compass hangs: Add `directConnection=true` and ensure TLS is off. Verify the tunnel is up with `scripts/verify-tunnel.sh`.
- Mongo not running: SSH in (step 1, without `-N`) and check `supervisorctl status` or run `mongosh --eval 'db.runCommand({ ping: 1 })'` in the container.

Security notes
- The current `mongod.conf` in this repo disables TLS and auth. SSH tunneling protects transport, but anyone with shell access to the service could connect. In production, create users and enable `security.authorization: enabled` in `mongod.conf` before exposing access more broadly.
- The `openssh-server` in the Dockerfile is not used by Render; their bastion attaches directly. You can remove SSH server from the image if desired.

