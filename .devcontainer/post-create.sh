#!/bin/bash
# Post-create script for GitHub Codespaces
# This script runs after the container is created

set -e

echo "🚀 Setting up Habitica development environment in Codespace..."

# Change to workspace directory
cd /workspaces/habitica

# Install dependencies
echo "📦 Installing Node.js dependencies..."
npm install --legacy-peer-deps 2>&1 | tail -20

# Install client dependencies
echo "📦 Installing client dependencies..."
cd website/client
npm install --legacy-peer-deps 2>&1 | tail -20
cd ../..

# Create config.json if it doesn't exist
if [ ! -f config.json ]; then
    echo "⚙️ Creating config.json..."
    cp config.json.example config.json
    
    # Update config for codespace
    cat > config.json << 'EOF'
{
    "BASE_URL": "http://localhost:3000",
    "CRON_SAFE_MODE": "false",
    "CRON_SEMI_SAFE_MODE": "false",
    "DISABLE_REQUEST_LOGGING": "false",
    "EMAIL_SERVER_AUTH_PASSWORD": "",
    "EMAIL_SERVER_AUTH_USER": "",
    "EMAIL_SERVER_URL": null,
    "ENABLE_CONSOLE_LOGS_IN_PROD": "true",
    "ENABLE_CONSOLE_LOGS_IN_TEST": "false",
    "FLAG_REPORT_EMAIL": "",
    "IGNORE_REDIRECT": "true",
    "INVITE_ONLY": "false",
    "MAINTENANCE_MODE": "false",
    "MONGODB_POOL_SIZE": "10",
    "NODE_DB_URI": "mongodb://localhost:27017/habitica-dev?replicaSet=rs&directConnection=true",
    "NODE_ENV": "development",
    "PATH": "bin:node_modules/.bin:/usr/local/bin:/usr/bin:/bin",
    "PORT": 3000,
    "PUSH_CONFIGS_APN_ENABLED": "false",
    "SESSION_SECRET": "codespace-dev-secret",
    "SESSION_SECRET_IV": "12345678901234567890123456789012",
    "SESSION_SECRET_KEY": "1234567890123456789012345678901234567890123456789012345678901234",
    "TRUSTED_DOMAINS": "",
    "WEB_CONCURRENCY": 1,
    "ENABLE_STACKDRIVER_TRACING": "false",
    "BLOCKED_IPS": "",
    "LOG_AMPLITUDE_EVENTS": "false",
    "RATE_LIMITER_ENABLED": "false",
    "CONTENT_SWITCHOVER_TIME_OFFSET": 8
}
EOF
fi

# Initialize MongoDB replica set (retry logic)
echo "🔧 Initializing MongoDB replica set..."
for i in {1..30}; do
    if mongosh --quiet --eval "rs.status()" > /dev/null 2>&1; then
        echo "✅ MongoDB replica set already initialized"
        break
    fi
    
    if mongosh --quiet --eval "rs.initiate()" > /dev/null 2>&1; then
        echo "✅ MongoDB replica set initialized successfully"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "⚠️ MongoDB replica set initialization timed out (this is OK, we'll try later)"
    else
        echo "Waiting for MongoDB... attempt $i/30"
        sleep 2
    fi
done

# Create helpful aliases
echo "📝 Creating helpful aliases..."
cat >> ~/.bashrc << 'EOF'

# Habitica development aliases
alias habitica-start='npm start'
alias habitica-test='npm test'
alias habitica-client='cd /workspaces/habitica/website/client && npm run serve'
alias habitica-build='npm run build'
alias habitica-lint='npm run lint'
alias mongo-shell='mongosh'
alias mongo-status='mongosh --eval "rs.status()"'
alias mongo-init='mongosh --eval "rs.initiate()"'

# Show welcome message on new terminal
if [ -f /workspaces/habitica/.devcontainer/welcome.txt ]; then
    cat /workspaces/habitica/.devcontainer/welcome.txt
fi
EOF

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

# Create a quick start script
echo "📋 Creating quick start script..."
cat > /workspaces/habitica/codespace-start.sh << 'EOF'
#!/bin/bash
# Quick start script for GitHub Codespace

echo "🎮 Starting Habitica in development mode..."
echo ""
echo "This will:"
echo "1. Build the client"
echo "2. Start the server"
echo ""

# Ensure MongoDB is ready
echo "Checking MongoDB..."
for i in {1..10}; do
    if mongosh --quiet --eval "rs.status()" > /dev/null 2>&1; then
        echo "✅ MongoDB is ready"
        break
    fi
    if [ $i -eq 1 ]; then
        echo "Initializing MongoDB replica set..."
        mongosh --quiet --eval "rs.initiate()" > /dev/null 2>&1 || true
    fi
    sleep 2
done

# Build client
echo ""
echo "📦 Building client..."
cd /workspaces/habitica/website/client
npm run build

# Start server
echo ""
echo "🚀 Starting server..."
cd /workspaces/habitica
npm start
EOF

chmod +x /workspaces/habitica/codespace-start.sh

echo ""
echo "✅ Setup complete!"
echo ""
cat .devcontainer/welcome.txt
