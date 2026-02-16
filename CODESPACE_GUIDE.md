# GitHub Codespaces Guide for Habitica

## 🚀 Quick Start in Codespaces

GitHub Codespaces provides a complete, configured development environment in your browser. No local setup required!

### Launch Your Codespace

1. **Click the button** (or follow these steps):
   - Go to the repository on GitHub
   - Click the green **"Code"** button
   - Select the **"Codespaces"** tab
   - Click **"Create codespace on copilot/add-user-action-history"**

2. **Wait for setup** (2-3 minutes):
   - The container will build
   - Dependencies will install automatically
   - MongoDB will initialize

3. **Start developing!**

### 🎯 What You Get

Your codespace includes:
- ✅ Node.js 20 pre-installed
- ✅ MongoDB 7.0 with replica set
- ✅ All dependencies installed
- ✅ VS Code extensions (ESLint, Vue, Docker, MongoDB)
- ✅ Helpful aliases and commands
- ✅ Port forwarding for web access

## 📋 First Steps

After your codespace launches:

### 1. Start the Application

```bash
# Quick start (builds client and starts server)
./codespace-start.sh

# Or manually:
npm start
```

### 2. Access Your Instance

Your Habitica instance will be available at:
```
https://{your-codespace-name}-3000.app.github.dev
```

VS Code will show a popup when port 3000 is forwarded. Click **"Open in Browser"**.

### 3. Create Your First Account

1. Open the forwarded URL
2. Click "Register"
3. Create your account
4. Start using Habitica!

## 🎮 Development Workflow

### Starting the Server

```bash
# Option 1: Quick start script (recommended for first time)
./codespace-start.sh

# Option 2: Direct start (if already built)
npm start

# Option 3: Development mode with hot reload
npm run start:dev
```

### Building the Client

```bash
cd website/client
npm run build

# Or for development with hot reload
npm run serve
```

### Running Tests

```bash
# Run all tests
npm test

# Run specific tests
npm run test:api-v3

# Run linter
npm run lint
```

### Database Operations

```bash
# Access MongoDB shell
mongosh

# Check replica set status
mongosh --eval "rs.status()"

# View databases
mongosh --eval "show dbs"

# Access habitica-dev database
mongosh habitica-dev

# Inside mongosh:
show collections
db.taskactions.find().limit(5)
db.users.countDocuments()
```

## 🔧 Helpful Aliases

The following aliases are automatically configured:

```bash
habitica-start      # Start the server
habitica-test       # Run tests
habitica-client     # Start client dev server
habitica-build      # Build the application
habitica-lint       # Run linter
mongo-shell         # Open MongoDB shell
mongo-status        # Check MongoDB status
mongo-init          # Initialize replica set
```

## 🌐 Testing Action History Feature

### 1. Create Tasks

```bash
# Access your instance in the browser
# Go to Tasks page
# Create some habits, dailies, and todos
```

### 2. Score Tasks

- Click on habits (+ and - buttons)
- Complete dailies
- Check off todos
- Purchase rewards

### 3. View Action History

1. Go to your profile (click your avatar)
2. Click the **"Action History"** tab
3. See all your task actions logged!

### 4. Test API Directly

```bash
# Get your API credentials from Settings -> API
# Then test the API:

USER_ID="your-user-id"
API_KEY="your-api-key"

curl -H "x-api-user: $USER_ID" \
     -H "x-api-key: $API_KEY" \
     https://{codespace-url}/api/v3/user/action-history
```

## 📊 Monitoring

### View Logs

```bash
# Server logs (if running in background)
tail -f server.log

# MongoDB logs
docker logs devcontainer_db_1 -f
```

### Check Service Status

```bash
# Check what's running on ports
netstat -tulpn | grep -E '(3000|27017)'

# Check MongoDB
mongosh --eval "db.serverStatus()"

# Check Node.js processes
ps aux | grep node
```

## 🛠️ Common Tasks

### Resetting the Database

```bash
# Access MongoDB
mongosh habitica-dev

# Drop all collections
db.dropDatabase()

# Restart the server to recreate with seed data
```

### Clearing Node Modules

```bash
# If you have dependency issues
rm -rf node_modules website/client/node_modules
npm install --legacy-peer-deps
cd website/client && npm install --legacy-peer-deps
```

### Rebuilding Everything

```bash
# Clean build
npm run clean
npm run build
cd website/client && npm run build
```

## 🐛 Troubleshooting

### Server Won't Start

**Error: MongoDB connection failed**
```bash
# Initialize replica set
mongosh --eval "rs.initiate()"

# Wait a few seconds, then restart server
npm start
```

**Error: Port 3000 already in use**
```bash
# Find and kill the process
lsof -ti:3000 | xargs kill -9

# Or use a different port
PORT=3001 npm start
```

### MongoDB Issues

**Replica set not initialized**
```bash
mongosh --eval "rs.initiate()"
```

**Can't connect to MongoDB**
```bash
# Check if MongoDB is running
ps aux | grep mongo

# If not running, the docker-compose should have started it
# Check docker containers:
docker ps
```

### Client Build Issues

**Error: Out of memory**
```bash
# Increase Node memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
cd website/client && npm run build
```

**Dependencies outdated**
```bash
cd website/client
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

## 🔒 Security Notes

### Codespace Security

- ✅ Codespaces are private by default
- ✅ Default secrets are for development only
- ⚠️ Don't commit real secrets to the repository
- ⚠️ Codespace URLs are unique but shareable

### Production Deployment

The codespace is for **development only**. For production:
- Use strong secrets (see `.env.example`)
- Use HTTPS
- Use proper MongoDB authentication
- Follow the [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

## 💡 Pro Tips

### Multiple Terminal Windows

1. Split terminal: `Ctrl + Shift + 5` (or click split icon)
2. Run server in one, client dev in another
3. Keep MongoDB shell in a third

### VS Code Extensions

Pre-installed extensions:
- **ESLint** - Code linting
- **Prettier** - Code formatting
- **Vue Language Features (Volar)** - Vue.js support
- **Docker** - Container management
- **MongoDB** - Database explorer

### Keyboard Shortcuts

- `Ctrl + ~` - Toggle terminal
- `Ctrl + P` - Quick file open
- `Ctrl + Shift + F` - Search across files
- `F5` - Start debugging

### Port Forwarding

- Ports are automatically forwarded
- Access via: `https://{codespace}-{port}.app.github.dev`
- Make port public: Ports panel → Right-click → Port Visibility → Public

## 📚 Additional Resources

### Documentation Files

- **QUICK_START.md** - 15-minute Docker deployment
- **DEPLOYMENT_GUIDE.md** - Complete deployment reference
- **DOCKER_README.md** - Docker management
- **YOUR_DEPLOYMENT.md** - Production deployment guide

### Habitica Resources

- [Original Habitica](https://habitica.com)
- [Habitica Wiki](https://habitica.fandom.com/wiki/Habitica_Wiki)
- [API Documentation](https://habitica.com/apidoc)

### GitHub Resources

- [Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Dev Containers](https://containers.dev/)

## 🤝 Collaboration

### Sharing Your Codespace

You can share your codespace with others:
1. Go to codespace dashboard
2. Click `...` menu on your codespace
3. Select "Share codespace"
4. Share the link (they'll need GitHub access)

### Pair Programming

Use VS Code Live Share extension:
1. Install Live Share extension
2. Click "Live Share" in status bar
3. Share the link with collaborators

## 🔄 Stopping and Restarting

### Stop Your Codespace

Codespaces auto-stop after 30 minutes of inactivity. To manually stop:
1. Click Codespaces menu (bottom left)
2. Select "Stop Current Codespace"

### Restart Your Codespace

1. Go to GitHub repository
2. Click "Code" → "Codespaces"
3. Click on your existing codespace

Your data persists between sessions!

## 💾 Backup and Export

### Export Database

```bash
# Create backup
mongodump --db habitica-dev --out backup

# Download via VS Code
# Right-click backup folder → Download
```

### Export Code Changes

```bash
# Create a branch
git checkout -b my-feature

# Commit changes
git add .
git commit -m "My changes"

# Push to GitHub
git push origin my-feature
```

## 🎓 Learning Resources

### Learning Habitica Codebase

1. Start with `website/server/index.js` - Server entry point
2. Check `website/client/src/` - Vue.js frontend
3. Review `website/server/models/` - Database models
4. Explore `website/server/controllers/` - API endpoints

### Making Changes

1. **Backend**: Edit files in `website/server/`
2. **Frontend**: Edit files in `website/client/src/`
3. **Database**: Models in `website/server/models/`
4. **API**: Controllers in `website/server/controllers/`

### Testing Your Changes

1. Make changes
2. Save files (auto-save enabled)
3. Restart server: `npm start`
4. Test in browser
5. Check logs for errors

## ✅ Verification Checklist

After setup, verify:
- [ ] Codespace launched successfully
- [ ] MongoDB is running and initialized
- [ ] Server starts without errors (`npm start`)
- [ ] Can access web interface in browser
- [ ] Can create an account
- [ ] Can create tasks
- [ ] Can score tasks
- [ ] Can see "Action History" tab in profile
- [ ] Action history shows logged actions

## 🆘 Getting Help

### Logs to Check

1. **Terminal output** - Check for error messages
2. **Browser console** - F12 → Console tab
3. **MongoDB logs** - `docker logs devcontainer_db_1`

### Common Solutions

1. **Restart server** - `Ctrl+C` then `npm start`
2. **Rebuild client** - `cd website/client && npm run build`
3. **Reinitialize MongoDB** - `mongosh --eval "rs.initiate()"`
4. **Clear cache** - `npm run clean`
5. **Restart codespace** - Stop and start from GitHub

### Still Stuck?

- Check existing issues in the repository
- Review error messages carefully
- Try searching the error on GitHub/Stack Overflow
- Create a new issue with details

---

**Happy coding in your Codespace!** 🚀

You now have a fully functional Habitica development environment with the Action History feature, ready to use directly in your browser!
