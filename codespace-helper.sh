#!/bin/bash
# Quick development setup script for Codespace
# This provides an interactive menu for common tasks

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check MongoDB
check_mongodb() {
    if mongosh --quiet --eval "rs.status()" > /dev/null 2>&1; then
        print_color "$GREEN" "✅ MongoDB is running and ready"
        return 0
    else
        print_color "$YELLOW" "⚠️  MongoDB replica set not initialized"
        return 1
    fi
}

# Function to initialize MongoDB
init_mongodb() {
    print_color "$BLUE" "🔧 Initializing MongoDB replica set..."
    if mongosh --quiet --eval "rs.initiate()" > /dev/null 2>&1; then
        print_color "$GREEN" "✅ MongoDB replica set initialized"
        sleep 3
        return 0
    else
        print_color "$YELLOW" "⚠️  Could not initialize (might already be initialized)"
        return 1
    fi
}

# Function to start server
start_server() {
    print_color "$BLUE" "🚀 Starting Habitica server..."
    
    # Check MongoDB first
    if ! check_mongodb; then
        print_color "$YELLOW" "Attempting to initialize MongoDB..."
        init_mongodb
        sleep 2
    fi
    
    # Check if client is built
    if [ ! -d "website/client/dist" ]; then
        print_color "$YELLOW" "Client not built yet. Building now..."
        build_client
    fi
    
    print_color "$BLUE" "Starting server on port 3000..."
    npm start
}

# Function to build client
build_client() {
    print_color "$BLUE" "📦 Building client..."
    cd website/client
    npm run build
    cd ../..
    print_color "$GREEN" "✅ Client built successfully"
}

# Function to run client dev server
dev_client() {
    print_color "$BLUE" "🔥 Starting client development server..."
    cd website/client
    npm run serve
}

# Function to run tests
run_tests() {
    print_color "$BLUE" "🧪 Running tests..."
    npm test
}

# Function to run linter
run_linter() {
    print_color "$BLUE" "🔍 Running linter..."
    npm run lint
}

# Function to show database info
show_db_info() {
    print_color "$BLUE" "📊 Database Information:"
    echo ""
    
    if check_mongodb; then
        echo "Collections:"
        mongosh habitica-dev --quiet --eval "db.getCollectionNames()" 2>/dev/null || echo "  Could not retrieve collections"
        
        echo ""
        echo "User count:"
        mongosh habitica-dev --quiet --eval "db.users.countDocuments()" 2>/dev/null || echo "  0"
        
        echo ""
        echo "Task actions count:"
        mongosh habitica-dev --quiet --eval "db.taskactions.countDocuments()" 2>/dev/null || echo "  0"
    else
        print_color "$YELLOW" "MongoDB not ready. Try option 8 to initialize."
    fi
}

# Function to open MongoDB shell
open_mongo_shell() {
    print_color "$BLUE" "🗄️  Opening MongoDB shell..."
    print_color "$YELLOW" "Tip: Type 'show dbs' to list databases, 'use habitica-dev' to switch, 'exit' to quit"
    mongosh habitica-dev
}

# Function to show help
show_help() {
    print_color "$BLUE" "📖 Habitica Codespace Helper"
    echo ""
    echo "Quick commands:"
    echo "  npm start              - Start the server"
    echo "  npm test               - Run tests"
    echo "  npm run lint           - Run linter"
    echo "  mongosh                - Open MongoDB shell"
    echo ""
    echo "Aliases:"
    echo "  habitica-start         - Start server"
    echo "  habitica-test          - Run tests"
    echo "  habitica-client        - Start client dev server"
    echo "  habitica-build         - Build client"
    echo "  habitica-lint          - Run linter"
    echo "  mongo-shell            - Open MongoDB shell"
    echo "  mongo-status           - Check MongoDB status"
    echo "  mongo-init             - Initialize MongoDB replica set"
    echo ""
    echo "Documentation:"
    echo "  CODESPACE_GUIDE.md     - Complete codespace guide"
    echo "  DEPLOYMENT_GUIDE.md    - Deployment documentation"
    echo "  QUICK_START.md         - Quick start guide"
    echo ""
    print_color "$GREEN" "Press any key to continue..."
    read -n 1
}

# Function to show codespace URL
show_url() {
    if [ -n "$CODESPACE_NAME" ]; then
        URL="https://${CODESPACE_NAME}-3000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
        print_color "$GREEN" "🌐 Your Habitica instance URL:"
        print_color "$BLUE" "$URL"
        echo ""
        print_color "$YELLOW" "Note: The server must be running (option 1) to access this URL"
    else
        print_color "$YELLOW" "Not running in a Codespace environment"
        print_color "$BLUE" "Local URL: http://localhost:3000"
    fi
    echo ""
    print_color "$GREEN" "Press any key to continue..."
    read -n 1
}

# Main menu
show_menu() {
    clear
    print_color "$BLUE" "╔════════════════════════════════════════╗"
    print_color "$BLUE" "║   Habitica Codespace Helper Menu      ║"
    print_color "$BLUE" "╚════════════════════════════════════════╝"
    echo ""
    print_color "$GREEN" "1) 🚀 Start Server"
    print_color "$GREEN" "2) 📦 Build Client"
    print_color "$GREEN" "3) 🔥 Start Client Dev Server (hot reload)"
    print_color "$GREEN" "4) 🧪 Run Tests"
    print_color "$GREEN" "5) 🔍 Run Linter"
    print_color "$GREEN" "6) 📊 Show Database Info"
    print_color "$GREEN" "7) 🗄️  Open MongoDB Shell"
    print_color "$GREEN" "8) 🔧 Initialize MongoDB Replica Set"
    print_color "$GREEN" "9) 🌐 Show Access URL"
    print_color "$GREEN" "0) 📖 Show Help"
    print_color "$YELLOW" "q) 🚪 Quit"
    echo ""
    print_color "$BLUE" "Enter choice: "
}

# Main loop
main() {
    while true; do
        show_menu
        read -n 1 choice
        echo ""
        
        case $choice in
            1)
                start_server
                ;;
            2)
                build_client
                echo ""
                print_color "$GREEN" "Press any key to continue..."
                read -n 1
                ;;
            3)
                dev_client
                ;;
            4)
                run_tests
                echo ""
                print_color "$GREEN" "Press any key to continue..."
                read -n 1
                ;;
            5)
                run_linter
                echo ""
                print_color "$GREEN" "Press any key to continue..."
                read -n 1
                ;;
            6)
                show_db_info
                echo ""
                print_color "$GREEN" "Press any key to continue..."
                read -n 1
                ;;
            7)
                open_mongo_shell
                ;;
            8)
                init_mongodb
                echo ""
                print_color "$GREEN" "Press any key to continue..."
                read -n 1
                ;;
            9)
                show_url
                ;;
            0)
                show_help
                ;;
            q|Q)
                print_color "$GREEN" "👋 Goodbye!"
                exit 0
                ;;
            *)
                print_color "$RED" "Invalid option. Press any key to continue..."
                read -n 1
                ;;
        esac
    done
}

# Run main function
main
