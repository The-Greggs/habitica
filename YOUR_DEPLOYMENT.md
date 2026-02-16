# Your Deployment Path - Action History Feature

## Current Setup (Don't Touch!)

```
Current Stack:
├── Image: docker.io/awinterstein/habitica-server:latest
├── Port: (your current port)
├── Database: habitica (existing)
└── Status: Running (DO NOT MODIFY)
```

## New Stack Setup (What You'll Deploy)

```
New Stack with Action History:
├── Image: habitica-server:action-history (built locally)
├── Port: 3001 (different from current)
├── Database: habitica-action-history (separate)
└── Status: New deployment
```

## Deployment Steps for Your Environment

### Step 1: Prepare Your Server

SSH into your server where Docker is running:
```bash
ssh user@habitica.gregg.au
```

### Step 2: Clone and Build

```bash
# Create a new directory for the updated version
mkdir -p ~/habitica-action-history
cd ~/habitica-action-history

# Clone your fork
git clone https://github.com/The-Greggs/habitica.git .

# Switch to the action history branch
git checkout copilot/add-user-action-history

# Configure environment
cp .env.example .env
nano .env
```

**Edit .env with your settings:**
```bash
EMAIL_PASSWORD=your_gmail_app_password

# Generate these:
SESSION_SECRET=$(openssl rand -base64 32)
SESSION_SECRET_IV=$(openssl rand -hex 16)
SESSION_SECRET_KEY=$(openssl rand -hex 32)
```

### Step 3: Build the Image

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Build the Docker image (takes 10-15 minutes)
./scripts/build-docker.sh
```

### Step 4: Deploy New Stack

```bash
# Start the new stack
./scripts/deploy-docker.sh start

# Or manually:
docker-compose -f docker-compose.action-history.yml up -d
```

### Step 5: Verify It's Working

```bash
# Check containers are running
docker ps | grep habitica

# Test the server
curl http://localhost:3001/api/v3/status

# View logs
docker logs -f habitica-server-action-history
```

### Step 6: Configure Your Reverse Proxy

You have two options:

#### Option A: Test on a Different Subdomain (Recommended)

Add a new subdomain to test first:
```nginx
# /etc/nginx/sites-available/habitica-new
upstream habitica_new {
    server localhost:3001;
}

server {
    listen 443 ssl;
    server_name habitica-new.gregg.au;  # Different subdomain
    
    # Your existing SSL certificates
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://habitica_new;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable the new site
sudo ln -s /etc/nginx/sites-available/habitica-new /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Test at: https://habitica-new.gregg.au

#### Option B: Switch the Main Domain

Once you're confident, update your existing nginx config:

```nginx
# /etc/nginx/sites-available/habitica
upstream habitica {
    server localhost:3001;  # Change from old port to 3001
}

# Rest of config stays the same
```

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Both Stacks Running Side by Side

```
┌─────────────────────────────────────────────┐
│              habitica.gregg.au              │
│           (Nginx Reverse Proxy)             │
└───────────┬─────────────────────┬───────────┘
            │                     │
            ▼                     ▼
  ┌─────────────────┐   ┌─────────────────┐
  │   Old Stack     │   │   New Stack     │
  │   Port: ???     │   │   Port: 3001    │
  │   (existing)    │   │   (new)         │
  └─────────────────┘   └─────────────────┘
```

## Testing Checklist

Before switching production:

- [ ] New stack starts successfully
- [ ] Can access web interface
- [ ] Can register/login
- [ ] Can create tasks
- [ ] Can score tasks (habits, dailies)
- [ ] "Action History" tab appears in profile
- [ ] Actions are logged and displayed
- [ ] Email notifications work
- [ ] Performance is acceptable

## Migration Plan (If You Want Same Data)

To copy your existing users/tasks to the new deployment:

```bash
# Export from old database
docker exec YOUR_OLD_MONGO_CONTAINER mongodump --db habitica --out /backup
docker cp YOUR_OLD_MONGO_CONTAINER:/backup ./backup

# Import to new database
docker cp ./backup habitica-mongo-action-history:/backup
docker exec habitica-mongo-action-history mongorestore --db habitica-action-history /backup/habitica

# Restart new stack
./scripts/deploy-docker.sh restart
```

**Note:** Action history will be empty initially and will only start logging new actions.

## Your Specific Environment Variables

Based on your docker-compose snippet:

```yaml
# Your current setup:
BASE_URL=https://habitica.gregg.au
INVITE_ONLY=true
EMAIL_SERVER_URL=smtp.gmail.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_AUTH_USER=odgregg@gmail.com
EMAIL_SERVER_AUTH_PASSWORD=<your app password>
```

These are already configured in `docker-compose.action-history.yml` - just add your password to `.env`!

## Rollback Plan

If something goes wrong:

1. Your old stack is still running untouched
2. Just point your reverse proxy back to the old port
3. Stop the new stack: `./scripts/deploy-docker.sh stop`
4. No data loss in old deployment

## What Happens When You Score a Task

With the new feature:

```
User clicks habit "Exercise" (+)
         ↓
Task is scored (existing logic)
         ↓
Action logged to TaskAction collection ← NEW!
  {
    userId: "abc123",
    taskId: "task456",
    taskType: "habit",
    taskText: "Exercise",
    action: "scored_up",
    createdAt: "2026-02-16T10:30:00Z",
    delta: 5.2
  }
         ↓
User can view in Action History tab
```

## Monitoring Your New Deployment

```bash
# Quick health check
./scripts/deploy-docker.sh status

# View live logs
./scripts/deploy-docker.sh logs

# Check action count
docker exec habitica-mongo-action-history mongosh --eval \
  "use habitica-action-history; db.taskactions.countDocuments()"

# Check disk usage
docker system df

# Check container resources
docker stats habitica-server-action-history
```

## Support Contacts

- **Docker Issues**: Check DEPLOYMENT_GUIDE.md
- **Action History Feature**: GitHub repository issues
- **Email Setup**: Gmail App Passwords: https://myaccount.google.com/apppasswords

## Timeline

Estimated time for complete deployment:

- Environment setup: 5 minutes
- Docker build: 10-15 minutes
- Deploy and test: 5-10 minutes
- Reverse proxy config: 5 minutes
- **Total: ~30-40 minutes**

## Success Indicators

You'll know it's working when:

1. ✅ `docker ps` shows both containers running
2. ✅ `curl http://localhost:3001/api/v3/status` returns JSON
3. ✅ Can access the web interface
4. ✅ See "Action History" tab in your profile
5. ✅ Actions appear in the history after scoring tasks

---

**Ready to start?** Follow [QUICK_START.md](./QUICK_START.md) for detailed commands!
