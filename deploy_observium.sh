#!/bin/bash

# Deployment script for GPU Monitor with Observium RRD files
# Run this on your remote host (10.4.231.200)

echo "Deploying GPU Monitor with Observium RRD access..."

# Stop any existing container
docker stop gpumon-prod 2>/dev/null || true
docker rm gpumon-prod 2>/dev/null || true

# Build the production image
echo "Building production Docker image..."
docker build -f Dockerfile.prod -t gpumon:prod .

# Run the container with correct RRD path
echo "Starting container with RRD access..."
docker run -d \
  --name gpumon-prod \
  -p 8090:5000 \
  -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro \
  -v /var/log/gpumon:/app/logs \
  --restart unless-stopped \
  gpumon:prod

# Wait for container to start
echo "Waiting for container to start..."
sleep 5

# Check container status
echo "Container status:"
docker ps | grep gpumon-prod

# Test RRD access
echo "Testing RRD access..."
docker exec -it gpumon-prod python3 test_rrd_access.py

echo "Deployment complete!"
echo "Access GPU Monitor at: http://10.4.231.200:8090"
