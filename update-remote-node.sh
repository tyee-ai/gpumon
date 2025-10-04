#!/bin/bash

# Update script for remote GPU monitor nodes
# Usage: ./update-remote-node.sh <remote-ip>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <remote-ip>"
    echo "Example: $0 10.9.231.200"
    exit 1
fi

REMOTE_IP=$1
echo "Updating remote node: $REMOTE_IP"

# SSH into the remote node and update
ssh root@$REMOTE_IP << 'EOF'
echo "Starting update process..."

# Navigate to gpumon directory
cd /root/gpumon

# Pull latest changes
echo "Pulling latest changes..."
git fetch origin
git checkout master
git pull origin master

# Verify SEA1 is in the config
echo "Verifying SEA1 configuration..."
if grep -q "SEA1" site_config.py; then
    echo "✅ SEA1 found in configuration"
else
    echo "❌ SEA1 NOT found in configuration"
    exit 1
fi

# Rebuild container
echo "Rebuilding container..."
docker compose -f docker-compose.remote.yml down
docker compose -f docker-compose.remote.yml up -d --build

# Wait for startup
echo "Waiting for container to start..."
sleep 15

# Check if running
echo "Checking container status..."
if docker ps | grep -q gpumon-remote; then
    echo "✅ Container is running"
else
    echo "❌ Container failed to start"
    docker logs gpumon-remote
    exit 1
fi

echo "✅ Update completed successfully!"
echo "Check the web interface at: http://$REMOTE_IP:8090 or https://$REMOTE_IP:8443"
EOF

if [ $? -eq 0 ]; then
    echo "✅ Remote node $REMOTE_IP updated successfully!"
else
    echo "❌ Failed to update remote node $REMOTE_IP"
fi
