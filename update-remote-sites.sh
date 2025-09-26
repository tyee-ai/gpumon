#!/bin/bash

# Update Remote GPU Monitor Sites
# This script updates the remote deployment with latest changes

set -e

echo "🔄 Updating Remote GPU Monitor Sites"
echo "===================================="

# Remote node details
REMOTE_HOST="10.15.231.200"
REMOTE_USER="root"  # Change this to your actual username

echo "📡 Connecting to remote node: $REMOTE_HOST"

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

# Verify we have the updated configuration
if [ -f "site_config.py" ]; then
    echo "✅ Found updated site_config.py"
    if grep -q "DFW1" site_config.py && grep -q "508" site_config.py; then
        echo "✅ Site configuration looks correct (DFW1: 508 nodes, 4064 GPUs)"
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
echo "New Features:"
echo "  ✅ Clickable site tabs (DFW1/DFW2)"
echo "  ✅ DFW1: 508 nodes, 4064 GPUs (4 clusters)"
echo "  ✅ DFW2: 254 nodes, 2032 GPUs (2 clusters)"
echo "  ✅ Fixed cluster name duplication"
echo "  ✅ Dynamic analytics page values"
echo ""

EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Remote sites updated successfully!"
    echo "🌐 Access the updated application at:"
    echo "   http://$REMOTE_HOST:8090"
    echo ""
    echo "The interface now includes:"
    echo "  • Clickable site tabs instead of dropdown"
    echo "  • DFW1: Allen Texas (508 nodes, 4064 GPUs)"
    echo "  • DFW2: Dallas-Fort Worth 2 (254 nodes, 2032 GPUs)"
else
    echo "❌ Failed to update remote sites"
    exit 1
fi
