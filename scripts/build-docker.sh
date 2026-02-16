#!/bin/bash
# Build script for Habitica with Action History feature

set -e  # Exit on any error

echo "=================================================="
echo "Building Habitica Docker Image with Action History"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="habitica-server"
TAG="action-history"
DOCKERFILE="Dockerfile"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}Error: Dockerfile not found${NC}"
    echo "Please run this script from the Habitica repository root directory"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker found"
echo -e "${GREEN}✓${NC} Dockerfile found"
echo ""

# Display current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "Current Git branch: ${YELLOW}${CURRENT_BRANCH}${NC}"
echo ""

# Confirm before building
echo -e "${YELLOW}This will build the Docker image with the following settings:${NC}"
echo "  Image name: ${IMAGE_NAME}"
echo "  Tag: ${TAG}"
echo "  Target: server"
echo ""
read -p "Continue with build? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled"
    exit 0
fi

echo ""
echo "Starting build process..."
echo "This may take 10-15 minutes depending on your system..."
echo ""

# Build the server image
docker build \
    --target server \
    --tag ${IMAGE_NAME}:${TAG} \
    --tag ${IMAGE_NAME}:latest \
    -f ${DOCKERFILE} \
    .

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=================================================="
    echo "✓ Build completed successfully!"
    echo -e "==================================================${NC}"
    echo ""
    echo "Image details:"
    docker images ${IMAGE_NAME}:${TAG}
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Copy .env.example to .env and fill in your configuration:"
    echo -e "   ${YELLOW}cp .env.example .env${NC}"
    echo "2. Edit .env with your settings"
    echo "3. Start the stack:"
    echo -e "   ${YELLOW}docker-compose -f docker-compose.action-history.yml up -d${NC}"
    echo ""
    echo "Or push to Docker Hub:"
    echo -e "   ${YELLOW}docker tag ${IMAGE_NAME}:${TAG} your-username/${IMAGE_NAME}:${TAG}${NC}"
    echo -e "   ${YELLOW}docker push your-username/${IMAGE_NAME}:${TAG}${NC}"
else
    echo ""
    echo -e "${RED}=================================================="
    echo "✗ Build failed with status code: $BUILD_STATUS"
    echo -e "==================================================${NC}"
    echo ""
    echo "Check the error messages above for details."
    exit $BUILD_STATUS
fi
