View Prod Data Locally (No SSH)
===============================

When SSH attachment to the private Mongo service isn’t available, you still have safe ways to explore prod data from your laptop.

Option A — Mongo Express Sidecar (fastest)
- What you get: A browser UI to view/query collections over Render’s internal network.
- Security: Protect with strong Basic Auth; disable when not needed.

Steps
1) Create a new Web Service in Render
   - Environment: Docker
   - Repository: this repo
   - Dockerfile path: `Dockerfile.mongo-express`
2) Set env vars
   - `ME_CONFIG_MONGODB_SERVER`: internal name of your Mongo private service (usually the service “Name”, e.g., `mongodb`)
   - `ME_CONFIG_MONGODB_PORT`: `27017`
   - `ME_CONFIG_BASICAUTH_USERNAME`: choose a strong username
   - `ME_CONFIG_BASICAUTH_PASSWORD`: choose a long random password
   - (Optional) `ME_CONFIG_MONGODB_AUTH`: `false` if your Mongo has no auth
3) Deploy
   - After it’s Live, open the service URL and log in with your Basic Auth credentials.
   - You can browse, filter, and edit documents. Treat as temporary admin and remove when done.

Notes
- This connects over Render’s internal network; the database itself stays private.
- Do not expose without Basic Auth. Consider time‑boxing the service (disable when not using).

Option B — Scheduled Dumps to S3 (safe + offline)
- What you get: A periodic dump of prod data you can download and explore locally with Compass.
- Security: Store dumps in a private bucket; rotate and expire objects.

High‑level steps
1) Create an S3 bucket and an IAM user with access only to `s3:PutObject` for a prefix (e.g., `s3://your-bucket/prod-mongo/`).
2) Add these env vars to a new Render “Cron Job” or “Worker” in the same team/region as Mongo:
   - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`
   - `S3_URI` (e.g., `s3://your-bucket/prod-mongo/`)
   - `MONGO_HOST` (internal name of your Mongo service, e.g., `mongodb`)
   - `MONGO_PORT` (e.g., `27017`)
3) Use a small image that has `mongodump` and `aws` CLI (e.g., base on `mongo:6` and install AWS CLI), and run:
   - `mongodump --host "$MONGO_HOST" --port "$MONGO_PORT" --archive --gzip | aws s3 cp - "$S3_URI$(date -u +%Y%m%d%H%M).archive.gz"`
4) Locally:
   - Download a dump: `aws s3 cp s3://your-bucket/prod-mongo/20250101*.archive.gz ./prod.archive.gz`
   - Explore: `mongorestore --archive=./prod.archive.gz --gzip --nsFrom='*' --nsTo='*' --drop --db local_copy`
   - Connect Compass to `mongodb://localhost:27017/local_copy` (after restoring to your local Mongo).

Option C — Managed Mirror (best long‑term UX)
- Set up a read‑only replica in MongoDB Atlas. Use Atlas’ IP allowlist and TLS to connect Compass directly without SSH.
- This avoids exposing your primary and gives you an isolated environment for BI/analytics tooling.

Which to choose?
- Need it now for browsing/editing: Use Option A (Mongo Express). Tear it down when done.
- Prefer offline, reproducible snapshots: Use Option B (S3 dumps) and restore locally.
- Ongoing analytics/BI: Use Option C (Atlas mirror) with read‑only users.

