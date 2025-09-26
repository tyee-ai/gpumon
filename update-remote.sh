#!/bin/bash

# Update Remote GPU Monitor Deployment
# This script updates the remote deployment to use the latest multisite configuration

set -e

echo "🔄 Updating Remote GPU Monitor Deployment"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Remote node details
REMOTE_HOST="10.15.231.200"
REMOTE_USER="root"  # Change this to your actual username

print_status "Updating remote deployment on $REMOTE_HOST..."

# SSH to remote node and update
ssh $REMOTE_USER@$REMOTE_HOST << 'EOF'
set -e

echo "🔄 Updating GPU Monitor on remote node..."

# Navigate to gpumon directory
cd /root/gpumon 2>/dev/null || cd /home/*/gpumon 2>/dev/null || {
    echo "❌ GPU Monitor directory not found. Please clone it first:"
    echo "git clone https://github.com/tyee-ai/gpumon.git"
    exit 1
}

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker compose -f docker-compose.remote.yml down 2>/dev/null || true
docker compose -f docker-compose.prod.yml down 2>/dev/null || true
docker stop gpumon-remote 2>/dev/null || true
docker stop gpumon-app-prod 2>/dev/null || true

# Pull latest changes
echo "📥 Pulling latest changes from multisite branch..."
git fetch origin
git checkout multisite
git pull origin multisite

# Verify we have the updated site_config.py
if [ -f "site_config.py" ]; then
    echo "✅ Found updated site_config.py"
    if grep -q "DFW1" site_config.py && grep -q "DFW2" site_config.py; then
        echo "✅ Site configuration looks correct (DFW1/DFW2)"
    else
        echo "❌ Site configuration doesn't look right"
        exit 1
    fi
else
    echo "❌ site_config.py not found"
    exit 1
fi

# Make deployment script executable
chmod +x deploy-remote-docker-ce.sh

# Build and start with the new configuration
echo "🚀 Building and starting updated container..."
docker compose -f docker-compose.remote.yml up -d --build

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 15

# Check if container is running
if docker ps | grep -q gpumon-remote; then
    echo "✅ Container is running"
else
    echo "❌ Container failed to start"
    docker logs gpumon-remote --tail 20
    exit 1
fi

# Test the application
echo "🧪 Testing the application..."
sleep 5

# Test health endpoint
if curl -s -f "http://localhost:8090/api/health" > /dev/null; then
    echo "✅ Health endpoint is responding"
else
    echo "⚠️ Health endpoint not responding"
fi

# Test sites API
if curl -s "http://localhost:8090/api/sites" | grep -q "DFW1"; then
    echo "✅ Sites API shows DFW1 (updated configuration)"
else
    echo "❌ Sites API doesn't show DFW1 - configuration may not be updated"
fi

# Get local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🎉 Update Complete!"
echo "=================="
echo "Access URLs:"
echo "  Local:  http://localhost:8090"
echo "  Remote: http://$LOCAL_IP:8090"
echo "  Health: http://$LOCAL_IP:8090/api/health"
echo ""
echo "Expected sites: DFW1 (Allen Texas) and DFW2 (Dallas-Fort Worth 2)"
echo ""

EOF

if [ $? -eq 0 ]; then
    print_success "Remote deployment updated successfully!"
    echo ""
    echo "🌐 Access the updated application at:"
    echo "   http://$REMOTE_HOST:8090"
    echo ""
    echo "The dropdown should now show:"
    echo "   • DFW1 - Dallas-Fort Worth 1 (254 nodes, 2032 GPUs)"
    echo "   • DFW2 - Dallas-Fort Worth 2 (254 nodes, 2032 GPUs)"
else
    print_error "Failed to update remote deployment"
    exit 1
fi
