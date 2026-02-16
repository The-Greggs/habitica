# Habitica Deployment Guide (Linux Docker Host)

This guide deploys this repository to a Linux Docker host, with special focus on running a **separate test instance** alongside an existing Habitica deployment.

---

## 1) Prerequisites

On the Linux host:

- Docker Engine 24+ and Docker Compose plugin (`docker compose`)
- Git
- At least 4 GB RAM available for build/runtime (more is better)
- Open host port for the app (example in this guide: `3300`)

Check:

```bash
docker --version
docker compose version
git --version
```

---

## 2) Why this can run side-by-side safely

Your current Habitica stays untouched if you isolate all three items below:

1. **Compose project name** (example: `habitica-test`)
2. **Host port** (example: `3300` instead of `3000`)
3. **Bind-mounted data directory** (example: `/srv/habitica-test/mongodb-data`)

In this repo, Mongo is internal to the compose network by default (not exposed to host), which already reduces collision risk.

---

## 3) Prepare deployment directory

```bash
sudo mkdir -p /srv/habitica-test
sudo chown -R $USER:$USER /srv/habitica-test
cd /srv/habitica-test
```

Clone your fork/branch (or copy this repo contents there):

```bash
git clone <YOUR_REPO_URL> .
# optional: checkout desired branch/tag
# git checkout <branch-or-tag>
```

---

## 4) Create a test override compose file

Do not edit the base compose file for test isolation. Create `docker-compose.test.yml`:

```yaml
services:
  server:
    environment:
      - BASE_URL=http://<HOST_OR_DOMAIN>:3300
      - INVITE_ONLY=false
      # optional mail settings if you want email features enabled
      # - EMAIL_SERVER_URL=smtp.example.com
      # - EMAIL_SERVER_PORT=587
      # - EMAIL_SERVER_AUTH_USER=mailer
      # - EMAIL_SERVER_AUTH_PASSWORD=secret
      # - ADMIN_EMAIL=admin@example.com
    ports:
      - "3300:3000"

  mongo:
    volumes:
      - /srv/habitica-test/mongodb-data/db:/data/db:rw
      - /srv/habitica-test/mongodb-data/dbconf:/data/configdb
```

> If your host enforces SELinux and Mongo cannot start due to permission labeling, add `:Z` to both bind mounts.

Create needed directories:

```bash
mkdir -p /srv/habitica-test/mongodb-data/db
mkdir -p /srv/habitica-test/mongodb-data/dbconf
```

---

## 5) Build and start test stack

From `/srv/habitica-test`:

```bash
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml up -d --build
```

Watch startup:

```bash
docker compose -p habitica-test logs -f mongo server
```

Health checks:

```bash
docker compose -p habitica-test ps
curl -I http://127.0.0.1:3300
```

If host firewall is enabled, allow the port:

```bash
# UFW example
sudo ufw allow 3300/tcp
```

---

## 6) First login and initial hardening

1. Open `http://<HOST_OR_DOMAIN>:3300`
2. Register first user (in this self-host build, first registered user gets admin rights)
3. After initial setup, disable public signups by changing in `docker-compose.test.yml`:

```yaml
- INVITE_ONLY=true
```

Then apply:

```bash
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml up -d
```

---

## 7) Reverse proxy (recommended)

Prefer HTTPS through your reverse proxy (Nginx/Caddy/Traefik). Route a test hostname (example: `habitica-test.example.com`) to `http://127.0.0.1:3300` on the Docker host.

Then set:

```yaml
- BASE_URL=https://habitica-test.example.com
```

Re-apply compose:

```bash
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml up -d
```

---

## 8) Update workflow

Pull latest code and rebuild:

```bash
cd /srv/habitica-test
git pull
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml up -d --build
```

Check logs after update:

```bash
docker compose -p habitica-test logs -f --tail=200 server mongo
```

---

## 9) Backup and restore (Mongo data)

### Backup

```bash
mkdir -p /srv/habitica-test/backups

docker exec -i $(docker compose -p habitica-test ps -q mongo) \
  mongodump --archive --gzip --db habitica \
  > /srv/habitica-test/backups/habitica-$(date +%F-%H%M).archive.gz
```

### Restore (to this test stack)

```bash
cat /srv/habitica-test/backups/<backup-file>.archive.gz | \
  docker exec -i $(docker compose -p habitica-test ps -q mongo) \
  mongorestore --archive --gzip --drop
```

---

## 10) Stop, start, and remove test stack

```bash
# stop
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml stop

# start again
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml start

# remove containers/network but keep DB data
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml down

# remove everything including DB data (destructive)
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml down -v
```

---

## 11) Common issues and fixes

### Build fails during npm steps

- Re-run with fresh build cache disabled:

```bash
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml build --no-cache
```

### Mongo starts but app cannot connect

- Confirm Mongo is healthy:

```bash
docker compose -p habitica-test ps
docker compose -p habitica-test logs mongo --tail=200
```

- Ensure `NODE_DB_URI` remains `mongodb://mongo/habitica` in base compose unless you intentionally changed topology.

### Port conflict

- Change host port mapping in `docker-compose.test.yml` (for example `4300:3000`) and update `BASE_URL` accordingly.

### Existing prod Habitica accidentally targeted

- Always include `-p habitica-test` and both compose files on every command.

---

## 12) Optional: run prebuilt image instead of local build

If you want faster deployment (without building this repo), use the image approach documented in [README.md](README.md). For testing your own code changes, keep using the build-from-source flow above.

---

## 13) Quick command cheat sheet

```bash
cd /srv/habitica-test

docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml up -d --build
docker compose -p habitica-test logs -f mongo server
docker compose -p habitica-test ps

docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml up -d
docker compose -p habitica-test -f docker-compose.yml -f docker-compose.test.yml down
```

---

## 14) Dockhand stacks (compose text) and your own image repository

Yes, you can run this with Dockhand stacks and your own image registry.

### Recommended model for Dockhand

- Build and push images in CI/CD (or once manually), then let Dockhand only `pull` and run.
- This is more reliable than in-stack builds and easier to roll back.

Use this stack file as your starting point:

- [dockhand-stack.habitica-test.yml](dockhand-stack.habitica-test.yml)

Before deploying it in Dockhand, replace:

- `ghcr.io/YOUR_ORG/habitica-server:YOUR_TAG`
- `BASE_URL=https://habitica-test.example.com`

Also create data directories on host:

```bash
mkdir -p /srv/habitica-test/mongodb-data/db
mkdir -p /srv/habitica-test/mongodb-data/dbconf
```

### Can compose clone+build by itself?

- Sometimes, using `build.context` with a Git URL if your environment supports BuildKit remote Git contexts.
- In Dockhand/stack UIs, support can vary.
- For predictable behavior, prebuilt images are strongly preferred.

### Create your own prebuilt image repository

You can absolutely host your own Habitica images in:

- GitHub Container Registry (`ghcr.io`)
- Docker Hub
- GitLab Registry
- Self-hosted registry (Harbor, `registry:2`)

Typical flow:

1. Build image from this repo:

```bash
docker build -t ghcr.io/<org>/habitica-server:<tag> --target server .
```

2. Push it:

```bash
docker login ghcr.io
docker push ghcr.io/<org>/habitica-server:<tag>
```

3. Reference that tag in your Dockhand stack `image:` and redeploy.

### Optional: add a client image too

This repo Dockerfile also has `target: client`. If you want split frontend/backend deployment:

```bash
docker build -t ghcr.io/<org>/habitica-client:<tag> --target client .
docker push ghcr.io/<org>/habitica-client:<tag>
```

For most self-hosted setups, starting with only the `server` image plus Mongo is simplest.

---

If you want, create a second guide for migrating from this test stack to a production stack on the same host with zero naming conflicts and a cleaner reverse-proxy layout.
