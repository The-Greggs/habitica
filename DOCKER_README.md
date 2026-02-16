# Docker Deployment - Action History Feature

This directory contains everything needed to deploy Habitica with the new Action History feature using Docker.

## 📦 What's Included

- **Dockerfile** - Multi-stage build configuration
- **docker-compose.action-history.yml** - Ready-to-use stack configuration
- **.env.example** - Environment variable template
- **scripts/build-docker.sh** - Automated build script
- **scripts/deploy-docker.sh** - Interactive deployment manager
- **DEPLOYMENT_GUIDE.md** - Comprehensive deployment documentation
- **QUICK_START.md** - Get running in 15 minutes

## 🚀 Quick Start (TL;DR)

```bash
# 1. Setup environment
cp .env.example .env
nano .env  # Fill in your EMAIL_PASSWORD and secrets

# 2. Build image
./scripts/build-docker.sh

# 3. Deploy
./scripts/deploy-docker.sh start

# 4. Access at http://localhost:3001
```

## 📖 Documentation

- **New to Docker deployment?** → Start with [QUICK_START.md](./QUICK_START.md)
- **Want all the details?** → See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- **Migrating existing data?** → Check the migration section in DEPLOYMENT_GUIDE.md

## 🎯 What You Get

The Action History feature provides:

- **Individual Action Logging** - Every habit click, daily completion recorded separately
- **Chronological View** - See your complete activity timeline
- **Flexible Filtering** - View last day, week, month, quarter, or year
- **Rich Details** - Task name, type, action, timestamp, and points earned

### New Tab in Profile

After deployment, you'll see a new "Action History" tab in your user profile:

```
Profile Tabs:
├── Profile (unchanged)
├── Stats (unchanged)
├── Achievements (unchanged)
└── Action History ← NEW!
```

## 🔧 Configuration Options

### Ports

By default, the new stack uses port **3001** to avoid conflicts with existing deployments.

To change it, edit `docker-compose.action-history.yml`:
```yaml
ports:
  - "YOUR_PORT:3000"
```

### Database

The new stack uses a separate database and MongoDB instance to avoid conflicts:
- Database name: `habitica-action-history`
- Container name: `habitica-mongo-action-history`
- Data directory: `./mongodb-action-history/`

### Environment Variables

See `.env.example` for all available options. Required settings:

| Variable | Description | Example |
|----------|-------------|---------|
| `EMAIL_PASSWORD` | Gmail app password | `abcd efgh ijkl mnop` |
| `SESSION_SECRET` | Random 32+ chars | Generate with `openssl rand -base64 32` |
| `SESSION_SECRET_IV` | 32 hex chars | Generate with `openssl rand -hex 16` |
| `SESSION_SECRET_KEY` | 64 hex chars | Generate with `openssl rand -hex 32` |

## 📊 Architecture

```
┌─────────────────────────────────────────┐
│           Reverse Proxy (Nginx)         │
│         (handles HTTPS/SSL)             │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│      Habitica Server Container          │
│    (Node.js + Client Static Files)      │
│         Port 3001:3000                  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│         MongoDB Container               │
│      (with Replica Set)                 │
│         Internal Network                │
└─────────────────────────────────────────┘
```

## 🔐 Security Checklist

- [ ] Use strong random SESSION_SECRET values
- [ ] Never commit `.env` file with real passwords
- [ ] Use Gmail App Password, not your regular password
- [ ] Keep MongoDB port internal (don't expose 27017)
- [ ] Use HTTPS in production via reverse proxy
- [ ] Regularly backup your database
- [ ] Keep Docker images updated

## 📝 Management Commands

### Using the Interactive Script

```bash
./scripts/deploy-docker.sh
# Shows menu with options:
# 1) Start stack
# 2) Stop stack
# 3) Restart stack
# 4) Show logs
# 5) Show status
```

### Using Command Line

```bash
./scripts/deploy-docker.sh start      # Start the stack
./scripts/deploy-docker.sh stop       # Stop the stack
./scripts/deploy-docker.sh restart    # Restart the stack
./scripts/deploy-docker.sh logs       # View logs
./scripts/deploy-docker.sh status     # Check status
```

### Using Docker Compose Directly

```bash
# Start
docker-compose -f docker-compose.action-history.yml up -d

# Stop
docker-compose -f docker-compose.action-history.yml down

# View logs
docker-compose -f docker-compose.action-history.yml logs -f

# Status
docker-compose -f docker-compose.action-history.yml ps
```

## 🔍 Monitoring

### Check Container Status
```bash
docker ps | grep habitica
```

### View Logs
```bash
# All logs
docker-compose -f docker-compose.action-history.yml logs -f

# Just server
docker logs -f habitica-server-action-history

# Just MongoDB
docker logs -f habitica-mongo-action-history
```

### Check Database
```bash
# Access MongoDB shell
docker exec -it habitica-mongo-action-history mongosh

# In the shell:
use habitica-action-history
show collections
db.taskactions.countDocuments()  # Number of logged actions
```

### Health Checks
```bash
# Server health
curl http://localhost:3001/api/v3/status

# MongoDB health
docker exec habitica-mongo-action-history mongosh --eval "rs.status()"
```

## 💾 Backup & Restore

### Backup
```bash
# Create backup
docker exec habitica-mongo-action-history \
  mongodump --out=/data/backup

# Copy to host
docker cp habitica-mongo-action-history:/data/backup \
  ./backup-$(date +%Y%m%d)
```

### Restore
```bash
# Copy backup to container
docker cp ./backup-20260216 \
  habitica-mongo-action-history:/data/restore

# Restore database
docker exec habitica-mongo-action-history \
  mongorestore --drop /data/restore
```

## 🆘 Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs habitica-server-action-history

# Verify .env file
cat .env

# Check port availability
netstat -tulpn | grep 3001
```

### Database Connection Issues
```bash
# Check MongoDB health
docker exec habitica-mongo-action-history mongosh --eval "rs.status()"

# Initialize replica set if needed
docker exec -it habitica-mongo-action-history mongosh
> rs.initiate()
```

### Action History Not Working
1. Check browser console (F12) for errors
2. Verify API endpoint: `curl http://localhost:3001/api/v3/user/action-history`
3. Check server logs for TaskAction errors
4. Verify MongoDB has taskactions collection

### Build Failures
```bash
# Clear Docker cache
docker system prune -a

# Rebuild with no cache
docker build --no-cache --target server -t habitica-server:action-history .
```

## 🔄 Updating

To update your deployment with new changes:

```bash
# 1. Pull latest changes
git pull origin copilot/add-user-action-history

# 2. Rebuild image
./scripts/build-docker.sh

# 3. Restart stack
./scripts/deploy-docker.sh restart
```

## 🧹 Cleanup

To remove the deployment:

```bash
# Stop and remove containers
docker-compose -f docker-compose.action-history.yml down

# Remove data (WARNING: Deletes database!)
rm -rf mongodb-action-history/

# Remove images
docker rmi habitica-server:action-history
```

## 📞 Support

- **Documentation Issues**: Check DEPLOYMENT_GUIDE.md
- **Action History Feature**: GitHub Issues
- **Docker Questions**: Docker documentation
- **Original Habitica**: Upstream repository

## 📜 License

This project maintains the same license as the upstream Habitica project. See LICENSE file for details.

---

**Ready to deploy?** Start with [QUICK_START.md](./QUICK_START.md) for step-by-step instructions!
