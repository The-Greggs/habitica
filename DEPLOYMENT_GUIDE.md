# Docker Deployment Guide - Action History Feature

This guide will help you deploy the updated Habitica with the new Action History feature to a new Docker stack without affecting your existing deployment.

## Overview

The action history feature adds:
- Individual task action logging (every habit click, daily completion, etc.)
- New API endpoint: `/api/v3/user/action-history`
- New "Action History" tab in user profiles
- New MongoDB collection: `TaskAction`

## Prerequisites

- Docker and Docker Compose installed
- Git installed
- Access to your server/host machine
- Your existing stack should remain untouched

## Option 1: Build Your Own Docker Image (Recommended)

This option allows you to build a custom image with your changes.

### Step 1: Clone This Repository

```bash
# Clone your fork with the action history feature
git clone https://github.com/The-Greggs/habitica.git habitica-with-history
cd habitica-with-history

# Switch to the branch with action history
git checkout copilot/add-user-action-history
```

### Step 2: Build the Docker Image

```bash
# Build the server image
docker build -t habitica-server:action-history --target server .

# Optional: Build the client image (if using separate client container)
docker build -t habitica-client:action-history --target client .
```

This will take several minutes as it installs dependencies and builds the application.

### Step 3: Create New Docker Compose Configuration

Create a new file `docker-compose-new.yml` in a different directory (to avoid conflicts):

```yaml
version: "3"
services:
  server-new:
    image: habitica-server:action-history
    container_name: habitica-server-new
    restart: unless-stopped
    depends_on:
      - mongo-new
    environment:
      - NODE_DB_URI=mongodb://mongo-new/habitica-new
      - BASE_URL=https://habitica.gregg.au
      - INVITE_ONLY=true
      - EMAIL_SERVER_URL=smtp.gmail.com
      - EMAIL_SERVER_PORT=587
      - EMAIL_SERVER_AUTH_USER=odgregg@gmail.com
      - EMAIL_SERVER_AUTH_PASSWORD=${EMAIL_PASSWORD}
      - ADMIN_EMAIL=odgregg@gmail.com
      - SESSION_SECRET=${SESSION_SECRET}
      - SESSION_SECRET_IV=${SESSION_SECRET_IV}
      - SESSION_SECRET_KEY=${SESSION_SECRET_KEY}
    ports:
      - "3001:3000"  # Use different port to avoid conflict with existing stack
    networks:
      - habitica-new
    volumes:
      - ./logs:/var/lib/habitica/logs

  mongo-new:
    image: docker.io/mongo:7.0  # Use specific version for stability
    container_name: habitica-mongo-new
    restart: unless-stopped
    hostname: mongo-new
    command: ["--replSet", "rs", "--bind_ip_all", "--port", "27017"]
    healthcheck:
      test: echo "try { rs.status() } catch (err) { rs.initiate() }" | mongosh --port 27017 --quiet
      interval: 10s
      timeout: 30s
      start_period: 0s
      start_interval: 1s
      retries: 30
    volumes:
      - ./mongodb-new/db:/data/db:rw
      - ./mongodb-new/dbconf:/data/configdb
    networks:
      habitica-new:
        aliases:
          - mongo-new

networks:
  habitica-new:
    driver: bridge
```

### Step 4: Create Environment File

Create a `.env` file in the same directory as your docker-compose file:

```bash
# Email password
EMAIL_PASSWORD=your_gmail_app_password_here

# Session secrets (generate random strings)
SESSION_SECRET=your_random_secret_here_min_32_chars
SESSION_SECRET_IV=12345678901234567890123456789012
SESSION_SECRET_KEY=1234567890123456789012345678901234567890123456789012345678901234
```

**Important**: Generate proper random secrets:
```bash
# Generate SESSION_SECRET (at least 32 characters)
openssl rand -base64 32

# Generate SESSION_SECRET_IV (32 characters)
openssl rand -hex 16

# Generate SESSION_SECRET_KEY (64 characters)
openssl rand -hex 32
```

### Step 5: Deploy the New Stack

```bash
# Start the new stack
docker-compose -f docker-compose-new.yml up -d

# Check logs
docker-compose -f docker-compose-new.yml logs -f server-new
```

### Step 6: Update Your Reverse Proxy

Update your nginx/caddy/traefik configuration to point to the new container on port 3001.

Example nginx configuration:
```nginx
upstream habitica_new {
    server localhost:3001;
}

server {
    listen 80;
    server_name habitica-new.gregg.au;  # Use a different subdomain for testing
    
    location / {
        proxy_pass http://habitica_new;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Option 2: Use Pre-built Image from Docker Hub

If you want to use a pre-built image (once you push it):

### Step 1: Push Your Image to Docker Hub

```bash
# Tag the image
docker tag habitica-server:action-history your-dockerhub-username/habitica-server:action-history

# Login to Docker Hub
docker login

# Push the image
docker push your-dockerhub-username/habitica-server:action-history
```

### Step 2: Update Docker Compose to Use Your Image

In your `docker-compose-new.yml`, change:
```yaml
services:
  server-new:
    image: your-dockerhub-username/habitica-server:action-history
    # ... rest of config
```

## Data Migration (Optional)

If you want to migrate data from your existing deployment:

### Export from Old Database

```bash
# Export user data
docker exec habitica-mongo mongodump --db habitica --out /backup

# Copy backup from container
docker cp habitica-mongo:/backup ./backup
```

### Import to New Database

```bash
# Copy backup to new container
docker cp ./backup habitica-mongo-new:/backup

# Import data
docker exec habitica-mongo-new mongorestore --db habitica-new /backup/habitica
```

**Note**: The new TaskAction collection will be empty initially. It will only start logging actions after the new deployment is running.

## Verification

Once deployed, verify the action history feature:

1. **Access your new instance**: Visit your new URL
2. **Log in** with your account
3. **Perform some task actions**: Click habits, complete dailies
4. **Check Action History tab**: 
   - Go to your profile
   - Click the "Action History" tab
   - You should see your recent actions

## Monitoring

Check that everything is working:

```bash
# Check container status
docker-compose -f docker-compose-new.yml ps

# View server logs
docker-compose -f docker-compose-new.yml logs -f server-new

# View MongoDB logs
docker-compose -f docker-compose-new.yml logs -f mongo-new

# Check MongoDB collections
docker exec -it habitica-mongo-new mongosh
> use habitica-new
> show collections
> db.taskactions.countDocuments()  # Should show count of logged actions
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs habitica-server-new

# Check if port is already in use
netstat -tulpn | grep 3001

# Try rebuilding
docker-compose -f docker-compose-new.yml down
docker-compose -f docker-compose-new.yml up -d --build
```

### Database Connection Issues

```bash
# Check if MongoDB is healthy
docker exec habitica-mongo-new mongosh --eval "rs.status()"

# If replica set not initialized
docker exec -it habitica-mongo-new mongosh
> rs.initiate()
```

### Action History Not Showing

1. Check browser console for errors (F12)
2. Verify API endpoint is accessible: 
   ```bash
   curl -H "x-api-user: YOUR_USER_ID" -H "x-api-key: YOUR_API_KEY" \
        https://habitica.gregg.au/api/v3/user/action-history
   ```
3. Check server logs for errors related to TaskAction

## Switching Between Old and New Deployments

Both stacks can run simultaneously:
- **Old stack**: Runs on port 3000 (or your current port)
- **New stack**: Runs on port 3001

Use your reverse proxy to switch between them, or use different subdomains for testing.

## Final Cutover

Once you're satisfied with the new deployment:

1. **Backup your data** from both deployments
2. **Stop the old stack**: 
   ```bash
   docker-compose down  # in old stack directory
   ```
3. **Update reverse proxy** to point to new stack permanently
4. **Optional**: Remove old containers and images to free space

## Rollback Plan

If you need to rollback:

1. Stop the new stack:
   ```bash
   docker-compose -f docker-compose-new.yml down
   ```
2. Your old stack should still be running or can be restarted
3. Update reverse proxy back to old stack

## Security Notes

- **Never commit `.env` file** with real passwords to git
- Use **strong random session secrets**
- Enable **HTTPS** in production via reverse proxy
- Keep your **MongoDB port** (27017) internal to Docker network only
- Regularly **backup your database**

## Support

For issues with:
- **Action History feature**: Check this repository's issues
- **Docker deployment**: See Docker documentation
- **Original Habitica**: See upstream repository

## Summary of Changes

The action history feature adds these new components:
- **Backend**: New TaskAction model and API endpoint
- **Frontend**: New profile tab with action history table
- **Database**: New TaskAction collection (created automatically)

All changes are backward compatible and won't affect existing functionality.
