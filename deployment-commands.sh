#!/bin/bash
# Complete Deployment Commands - Copy and Paste Ready
# For deploying Habitica with Action History feature

# =============================================================================
# PART 1: INITIAL SETUP (Run once)
# =============================================================================

# Create directory and clone repository
mkdir -p ~/habitica-action-history
cd ~/habitica-action-history
git clone https://github.com/The-Greggs/habitica.git .
git checkout copilot/add-user-action-history

# =============================================================================
# PART 2: CONFIGURATION (Run once)
# =============================================================================

# Copy environment template
cp .env.example .env

# Generate secrets and save them
echo "# Generated secrets - save these!" > .env-secrets
echo "EMAIL_PASSWORD=YOUR_GMAIL_APP_PASSWORD" >> .env-secrets
echo "SESSION_SECRET=$(openssl rand -base64 32)" >> .env-secrets
echo "SESSION_SECRET_IV=$(openssl rand -hex 16)" >> .env-secrets
echo "SESSION_SECRET_KEY=$(openssl rand -hex 32)" >> .env-secrets

# Display secrets
cat .env-secrets
echo ""
echo "Copy these values to your .env file!"

# Edit .env file
nano .env

# =============================================================================
# PART 3: BUILD (Run once, or when code changes)
# =============================================================================

# Make scripts executable
chmod +x scripts/*.sh

# Build Docker image
./scripts/build-docker.sh

# Verify image was created
docker images | grep habitica-server

# =============================================================================
# PART 4: DEPLOY (Run once)
# =============================================================================

# Start the stack
./scripts/deploy-docker.sh start

# Or use docker-compose directly
# docker-compose -f docker-compose.action-history.yml up -d

# =============================================================================
# PART 5: VERIFY (Run after deployment)
# =============================================================================

# Check if containers are running
docker ps | grep habitica

# Check container logs
docker logs habitica-server-action-history
docker logs habitica-mongo-action-history

# Test server health
curl http://localhost:3001/api/v3/status

# Check MongoDB status
docker exec habitica-mongo-action-history mongosh --eval "rs.status()"

# =============================================================================
# PART 6: MANAGEMENT COMMANDS (Use as needed)
# =============================================================================

# View all logs
./scripts/deploy-docker.sh logs

# Or docker-compose directly
# docker-compose -f docker-compose.action-history.yml logs -f

# Check status
./scripts/deploy-docker.sh status

# Restart stack
./scripts/deploy-docker.sh restart

# Stop stack
./scripts/deploy-docker.sh stop

# =============================================================================
# PART 7: DATABASE OPERATIONS
# =============================================================================

# Access MongoDB shell
docker exec -it habitica-mongo-action-history mongosh

# Inside mongosh, run these commands:
# use habitica-action-history
# show collections
# db.taskactions.countDocuments()
# db.taskactions.find().limit(5).pretty()
# exit

# One-liner to count actions
docker exec habitica-mongo-action-history mongosh --eval \
  "use habitica-action-history; db.taskactions.countDocuments()"

# One-liner to see latest actions
docker exec habitica-mongo-action-history mongosh --eval \
  "use habitica-action-history; db.taskactions.find().sort({createdAt:-1}).limit(5)"

# =============================================================================
# PART 8: BACKUP
# =============================================================================

# Create backup
docker exec habitica-mongo-action-history mongodump --out=/data/backup

# Copy backup to host
docker cp habitica-mongo-action-history:/data/backup ./backup-$(date +%Y%m%d-%H%M%S)

# =============================================================================
# PART 9: NGINX CONFIGURATION
# =============================================================================

# Create new nginx config for testing subdomain
sudo nano /etc/nginx/sites-available/habitica-new

# Paste this configuration:
cat << 'EOF'
upstream habitica_new {
    server localhost:3001;
}

server {
    listen 443 ssl http2;
    server_name habitica-new.gregg.au;
    
    # SSL Configuration (adjust paths as needed)
    ssl_certificate /path/to/your/fullchain.pem;
    ssl_certificate_key /path/to/your/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Proxy settings
    location / {
        proxy_pass http://habitica_new;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Client max body size (for avatars, etc)
    client_max_body_size 10M;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name habitica-new.gregg.au;
    return 301 https://$server_name$request_uri;
}
EOF

# Enable the site
sudo ln -s /etc/nginx/sites-available/habitica-new /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# =============================================================================
# PART 10: TESTING
# =============================================================================

# Test from server
curl -I https://habitica-new.gregg.au

# Test action history API (replace with your actual credentials)
curl -H "x-api-user: YOUR_USER_ID" \
     -H "x-api-key: YOUR_API_KEY" \
     https://habitica-new.gregg.au/api/v3/user/action-history

# =============================================================================
# PART 11: MONITORING
# =============================================================================

# Watch container logs live
docker logs -f habitica-server-action-history

# Check resource usage
docker stats habitica-server-action-history habitica-mongo-action-history

# Check disk usage
docker system df

# Check container health
docker inspect habitica-server-action-history | grep -A 5 Health

# =============================================================================
# PART 12: TROUBLESHOOTING
# =============================================================================

# If MongoDB won't start - initialize replica set
docker exec -it habitica-mongo-action-history mongosh
# Then in shell: rs.initiate()

# If container won't start - check logs
docker logs habitica-server-action-history

# If port conflict - check what's using port 3001
sudo netstat -tulpn | grep 3001

# Rebuild with no cache
docker build --no-cache --target server -t habitica-server:action-history .

# Clear Docker cache and rebuild everything
docker system prune -a
./scripts/build-docker.sh

# Restart everything
./scripts/deploy-docker.sh stop
./scripts/deploy-docker.sh start

# =============================================================================
# PART 13: MIGRATION (Optional - Copy data from old deployment)
# =============================================================================

# Export from old deployment (replace YOUR_OLD_MONGO with actual container name)
docker exec YOUR_OLD_MONGO mongodump --db habitica --out /backup
docker cp YOUR_OLD_MONGO:/backup ./old-backup

# Import to new deployment
docker cp ./old-backup habitica-mongo-action-history:/backup
docker exec habitica-mongo-action-history mongorestore --db habitica-action-history /backup/habitica

# Restart new stack
./scripts/deploy-docker.sh restart

# =============================================================================
# PART 14: CLEANUP (If you need to start over)
# =============================================================================

# Stop and remove containers
./scripts/deploy-docker.sh stop

# Remove all data (WARNING: This deletes everything!)
rm -rf mongodb-action-history/
rm -rf logs/

# Remove Docker images
docker rmi habitica-server:action-history

# =============================================================================
# PART 15: UPDATES (When you pull new code)
# =============================================================================

# Pull latest changes
cd ~/habitica-action-history
git pull origin copilot/add-user-action-history

# Rebuild image
./scripts/build-docker.sh

# Restart with new image
./scripts/deploy-docker.sh restart

# =============================================================================
# USEFUL ONE-LINERS
# =============================================================================

# Quick health check
docker ps | grep habitica && curl -s http://localhost:3001/api/v3/status | jq .

# Count total actions logged
docker exec habitica-mongo-action-history mongosh --quiet --eval \
  "use habitica-action-history; print('Total actions:', db.taskactions.countDocuments())"

# See latest 10 actions
docker exec habitica-mongo-action-history mongosh --quiet --eval \
  "use habitica-action-history; db.taskactions.find().sort({createdAt:-1}).limit(10).forEach(printjson)"

# Check if replica set is working
docker exec habitica-mongo-action-history mongosh --quiet --eval "rs.status().ok"

# Full status check
echo "=== Container Status ===" && \
docker ps --filter "name=habitica-.*-action-history" && \
echo "=== Server Health ===" && \
curl -s http://localhost:3001/api/v3/status | jq . && \
echo "=== Database Status ===" && \
docker exec habitica-mongo-action-history mongosh --quiet --eval "rs.status().ok"

# =============================================================================
# END OF COMMANDS
# =============================================================================
