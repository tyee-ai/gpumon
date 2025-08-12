#!/bin/bash

echo "🔒 RUNNING GPU MONITOR WITH PRIVILEGED ACCESS"
echo "============================================="

# Stop existing container
docker stop gpumon-prod 2>/dev/null || true
docker rm gpumon-prod 2>/dev/null || true

# Run with privileged access
docker run -d \
  --name gpumon-prod \
  -p 8090:5000 \
  --privileged \
  --cap-add=ALL \
  -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro \
  --restart unless-stopped \
  gpumon:prod

echo "✅ Container started with privileged access"
echo "🌐 Access at: http://localhost:8090"
echo "🔒 Container has elevated privileges for RRD access"
