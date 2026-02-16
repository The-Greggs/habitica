# Quick Start Guide - Docker Deployment

This guide will get you up and running with the Action History feature in under 15 minutes.

## Prerequisites

✅ Docker installed  
✅ Docker Compose installed  
✅ Git installed  

## Step-by-Step Instructions

### 1. Clone and Checkout

```bash
# Clone your repository
git clone https://github.com/The-Greggs/habitica.git habitica-action-history
cd habitica-action-history

# Checkout the branch with action history feature
git checkout copilot/add-user-action-history
```

### 2. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your settings
nano .env  # or use your preferred editor
```

**Required settings in .env:**
```bash
# Your Gmail app password (not your regular password!)
EMAIL_PASSWORD=your_app_password

# Generate these with: openssl rand -base64 32
SESSION_SECRET=your_random_32_char_string

# Generate with: openssl rand -hex 16
SESSION_SECRET_IV=your_32_hex_chars

# Generate with: openssl rand -hex 32
SESSION_SECRET_KEY=your_64_hex_chars
```

**Quick way to generate all secrets:**
```bash
echo "SESSION_SECRET=$(openssl rand -base64 32)"
echo "SESSION_SECRET_IV=$(openssl rand -hex 16)"
echo "SESSION_SECRET_KEY=$(openssl rand -hex 32)"
```

### 3. Build the Docker Image

```bash
# Make the build script executable (if not already)
chmod +x scripts/build-docker.sh

# Run the build script
./scripts/build-docker.sh
```

This will take 10-15 minutes. Go get a coffee! ☕

### 4. Deploy the Stack

```bash
# Make the deploy script executable (if not already)
chmod +x scripts/deploy-docker.sh

# Start the stack
./scripts/deploy-docker.sh start

# Or use docker-compose directly
docker-compose -f docker-compose.action-history.yml up -d
```

### 5. Verify Deployment

```bash
# Check if containers are running
docker ps | grep habitica

# View logs
docker-compose -f docker-compose.action-history.yml logs -f

# Or use the deploy script
./scripts/deploy-docker.sh status
./scripts/deploy-docker.sh logs
```

### 6. Access Your Instance

The server will be available at:
- **Local:** http://localhost:3001
- **Production:** Update your reverse proxy to point to port 3001

### 7. Test Action History Feature

1. Access your Habitica instance
2. Log in (or create an account if first time)
3. Create a habit and click it a few times
4. Go to your profile → Click "Action History" tab
5. You should see your recent actions! 🎉

## Common Issues

### Port 3001 Already In Use

Edit `docker-compose.action-history.yml` and change the port:
```yaml
ports:
  - "3002:3000"  # Use port 3002 instead
```

### MongoDB Won't Start

```bash
# Check if replica set needs initialization
docker exec -it habitica-mongo-action-history mongosh
> rs.initiate()
> exit
```

### Build Fails

```bash
# Clear Docker cache and rebuild
docker system prune -a
./scripts/build-docker.sh
```

### Can't Connect to Database

```bash
# Check if MongoDB is healthy
docker exec habitica-mongo-action-history mongosh --eval "rs.status()"

# Restart the stack
./scripts/deploy-docker.sh restart
```

## Update Your Reverse Proxy

### For Nginx

Add to your nginx configuration:
```nginx
upstream habitica_new {
    server localhost:3001;
}

server {
    listen 443 ssl;
    server_name habitica.gregg.au;
    
    # SSL certificates...
    
    location / {
        proxy_pass http://habitica_new;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### For Caddy

Add to your Caddyfile:
```
habitica.gregg.au {
    reverse_proxy localhost:3001
}
```

### For Traefik

Add labels to your docker-compose.yml:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.habitica.rule=Host(`habitica.gregg.au`)"
  - "traefik.http.services.habitica.loadbalancer.server.port=3000"
```

## Useful Commands

```bash
# View all logs
./scripts/deploy-docker.sh logs

# View just server logs
docker logs -f habitica-server-action-history

# View MongoDB logs
docker logs -f habitica-mongo-action-history

# Stop the stack
./scripts/deploy-docker.sh stop

# Start the stack
./scripts/deploy-docker.sh start

# Restart the stack
./scripts/deploy-docker.sh restart

# Check status
./scripts/deploy-docker.sh status

# Access MongoDB shell
docker exec -it habitica-mongo-action-history mongosh

# Check database collections
docker exec habitica-mongo-action-history mongosh --eval "use habitica-action-history; show collections"

# Count action history entries
docker exec habitica-mongo-action-history mongosh --eval "use habitica-action-history; db.taskactions.countDocuments()"
```

## Backup Your Data

```bash
# Backup MongoDB
docker exec habitica-mongo-action-history mongodump --out=/data/backup

# Copy backup from container
docker cp habitica-mongo-action-history:/data/backup ./backup-$(date +%Y%m%d)
```

## Clean Up (If Needed)

```bash
# Stop and remove containers
docker-compose -f docker-compose.action-history.yml down

# Remove all data (WARNING: This deletes your database!)
rm -rf mongodb-action-history/

# Remove images
docker rmi habitica-server:action-history
```

## Next Steps

1. **Test thoroughly** in your new deployment
2. **Backup your old deployment** before switching
3. **Update DNS/reverse proxy** when ready to go live
4. **Monitor logs** for the first few days

## Getting Help

- Check the full [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for detailed information
- Review Docker logs for specific error messages
- Check GitHub issues for similar problems

## Success Checklist

- ✅ Containers are running (`docker ps`)
- ✅ MongoDB is healthy (replica set initialized)
- ✅ Server responds to health check
- ✅ Can access web interface
- ✅ Can log in
- ✅ Can see "Action History" tab in profile
- ✅ Actions are being logged and displayed

If all items are checked, congratulations! 🎉 Your deployment is successful!
