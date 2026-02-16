#!/bin/bash
# Deployment script for Habitica with Action History feature

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================="
echo "Habitica Action History Deployment Script"
echo -e "==================================================${NC}"
echo ""

# Configuration
COMPOSE_FILE="docker-compose.action-history.yml"
ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker is not installed${NC}"
        echo "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Docker found"
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}✗ Docker Compose is not installed${NC}"
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Docker Compose found"
    
    # Check if compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo -e "${RED}✗ $COMPOSE_FILE not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Compose file found"
    
    # Check if .env exists
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${YELLOW}⚠${NC} .env file not found"
        if [ -f "$ENV_EXAMPLE" ]; then
            echo -e "${YELLOW}Creating .env from .env.example...${NC}"
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            echo -e "${YELLOW}⚠ IMPORTANT: Edit .env and configure your settings before continuing!${NC}"
            exit 1
        else
            echo -e "${RED}✗ .env.example not found${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}✓${NC} .env file found"
    
    echo ""
}

# Function to check if Docker image exists
check_image() {
    echo "Checking for Docker image..."
    if docker images | grep -q "habitica-server.*action-history"; then
        echo -e "${GREEN}✓${NC} Docker image found"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Docker image not found"
        echo ""
        echo "You need to build the image first:"
        echo -e "${YELLOW}  ./scripts/build-docker.sh${NC}"
        echo ""
        read -p "Would you like to build it now? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "./scripts/build-docker.sh" ]; then
                chmod +x ./scripts/build-docker.sh
                ./scripts/build-docker.sh
            else
                echo -e "${RED}✗ Build script not found${NC}"
                exit 1
            fi
        else
            echo "Please build the image first, then run this script again."
            exit 1
        fi
    fi
    echo ""
}

# Function to display current configuration
show_configuration() {
    echo -e "${BLUE}Current Configuration:${NC}"
    echo "  Compose file: $COMPOSE_FILE"
    echo "  Environment: $ENV_FILE"
    if docker compose -f "$COMPOSE_FILE" ps &> /dev/null 2>&1 || docker-compose -f "$COMPOSE_FILE" ps &> /dev/null 2>&1; then
        echo "  Status: Running"
    else
        echo "  Status: Not running"
    fi
    echo ""
}

# Function to start the stack
start_stack() {
    echo -e "${GREEN}Starting Habitica stack...${NC}"
    echo ""
    
    # Use docker compose or docker-compose depending on what's available
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" up -d
    else
        docker-compose -f "$COMPOSE_FILE" up -d
    fi
    
    echo ""
    echo -e "${GREEN}✓ Stack started successfully${NC}"
    echo ""
    echo "Waiting for services to be healthy..."
    sleep 5
    show_status
}

# Function to stop the stack
stop_stack() {
    echo -e "${YELLOW}Stopping Habitica stack...${NC}"
    echo ""
    
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" down
    else
        docker-compose -f "$COMPOSE_FILE" down
    fi
    
    echo ""
    echo -e "${GREEN}✓ Stack stopped${NC}"
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}Showing logs (Ctrl+C to exit)...${NC}"
    echo ""
    
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" logs -f
    else
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

# Function to show status
show_status() {
    echo -e "${BLUE}Container Status:${NC}"
    echo ""
    
    if docker compose version &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" ps
    else
        docker-compose -f "$COMPOSE_FILE" ps
    fi
    
    echo ""
    echo -e "${BLUE}Health Checks:${NC}"
    docker ps --filter "name=habitica-.*-action-history" --format "table {{.Names}}\t{{.Status}}"
    echo ""
}

# Function to restart the stack
restart_stack() {
    echo -e "${YELLOW}Restarting Habitica stack...${NC}"
    stop_stack
    echo ""
    start_stack
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}Select an action:${NC}"
    echo "1) Start stack"
    echo "2) Stop stack"
    echo "3) Restart stack"
    echo "4) Show logs"
    echo "5) Show status"
    echo "6) Exit"
    echo ""
    read -p "Enter choice [1-6]: " choice
    echo ""
    
    case $choice in
        1) start_stack ;;
        2) stop_stack ;;
        3) restart_stack ;;
        4) show_logs ;;
        5) show_status ;;
        6) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

# Main script execution
main() {
    check_prerequisites
    check_image
    show_configuration
    
    # If no arguments, show interactive menu
    if [ $# -eq 0 ]; then
        while true; do
            show_menu
        done
    else
        # Process command line arguments
        case "$1" in
            start)
                start_stack
                ;;
            stop)
                stop_stack
                ;;
            restart)
                restart_stack
                ;;
            logs)
                show_logs
                ;;
            status)
                show_status
                ;;
            *)
                echo "Usage: $0 {start|stop|restart|logs|status}"
                echo "Or run without arguments for interactive menu"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
