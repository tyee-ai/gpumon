#!/bin/bash

# GPU Monitor Docker CE Remote Deployment Script
# For deployment to 10.15.231.200

set -e  # Exit on any error

echo "🐳 GPU Monitor Docker CE Remote Deployment"
echo "=========================================="
echo "Target: 10.15.231.200"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "web_app.py" ] || [ ! -f "site_config.py" ]; then
    print_error "Required files not found. Please run this script from the gpumon directory."
    exit 1
fi

# Check if Docker is installed
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker CE first."
    echo "Run: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available. Please install Docker Compose plugin."
    exit 1
fi

print_success "Docker and Docker Compose are available"

# Check if we're on the correct branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "multisite" ]; then
    print_warning "Current branch is '$CURRENT_BRANCH', expected 'multisite'"
    read -p "Do you want to switch to multisite branch? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout multisite
        print_success "Switched to multisite branch"
    else
        print_warning "Continuing with current branch: $CURRENT_BRANCH"
    fi
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs
mkdir -p ssl

# Check RRD data path
RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
print_status "Checking RRD data path: $RRD_PATH"

if [ ! -d "$RRD_PATH" ]; then
    print_warning "RRD data path not found: $RRD_PATH"
    echo "Please update the RRD path in docker-compose.remote.yml"
    echo "Common locations:"
    echo "  - /opt/docker/volumes/docker-observium_config/_data/rrd"
    echo "  - /var/lib/ganglia/rrds"
    echo "  - /opt/ganglia/rrds"
    echo ""
    read -p "Enter the correct RRD path (or press Enter to continue with current): " CUSTOM_RRD_PATH
    if [ ! -z "$CUSTOM_RRD_PATH" ]; then
        sed -i "s|$RRD_PATH|$CUSTOM_RRD_PATH|g" docker-compose.remote.yml
        print_success "Updated RRD path to: $CUSTOM_RRD_PATH"
    fi
else
    print_success "RRD data path found: $RRD_PATH"
fi

# Stop any existing containers
print_status "Stopping any existing containers..."
docker compose -f docker-compose.remote.yml down 2>/dev/null || true

# Build and start the container
print_status "Building and starting the GPU Monitor container..."
docker compose -f docker-compose.remote.yml up -d --build

# Wait for container to start
print_status "Waiting for container to start..."
sleep 10

# Check container status
print_status "Checking container status..."
if docker ps | grep -q gpumon-remote; then
    print_success "Container is running"
else
    print_error "Container failed to start"
    echo "Container logs:"
    docker logs gpumon-remote
    exit 1
fi

# Test the application
print_status "Testing the application..."
sleep 5

# Get the local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Test health endpoint
if curl -s -f "http://localhost:8090/api/health" > /dev/null; then
    print_success "Health endpoint is responding"
else
    print_warning "Health endpoint not responding, checking logs..."
    docker logs gpumon-remote --tail 20
fi

# Test main page
if curl -s -f "http://localhost:8090/" > /dev/null; then
    print_success "Main page is accessible"
else
    print_warning "Main page not accessible"
fi

# Display access information
echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo ""
echo "Access URLs:"
echo "  Local:  http://localhost:8090"
echo "  Remote: http://$LOCAL_IP:8090"
echo "  Health: http://$LOCAL_IP:8090/api/health"
echo ""
echo "Useful Commands:"
echo "  View logs:    docker logs gpumon-remote -f"
echo "  Stop:         docker compose -f docker-compose.remote.yml down"
echo "  Restart:      docker compose -f docker-compose.remote.yml restart"
echo "  Update:       git pull && docker compose -f docker-compose.remote.yml up -d --build"
echo ""
echo "Current Site Configuration:"
echo "  DFW1: Allen Texas (254 nodes, 2,032 GPUs)"
echo "  DFW2: Dallas-Fort Worth 2 (254 nodes, 2,032 GPUs)"
echo ""

# Test API endpoints
print_status "Testing API endpoints..."
if curl -s "http://localhost:8090/api/sites" | grep -q "DFW1"; then
    print_success "Sites API is working"
else
    print_warning "Sites API may not be working correctly"
fi

print_success "Deployment completed successfully!"
