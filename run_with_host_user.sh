#!/bin/bash

echo "👤 RUNNING GPU MONITOR WITH HOST USER PERMISSIONS"
echo "================================================="

echo -e "\n1️⃣ Getting current user info..."
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "Current user: $CURRENT_USER (UID: $CURRENT_UID, GID: $CURRENT_GID)"

echo -e "\n2️⃣ Stopping existing container..."
docker stop gpumon-prod 2>/dev/null || true
docker rm gpumon-prod 2>/dev/null || true

echo -e "\n3️⃣ Starting container with host user permissions..."
docker run -d \
  --name gpumon-prod \
  -p 8090:5000 \
  --user "$CURRENT_UID:$CURRENT_GID" \
  -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro \
  --restart unless-stopped \
  gpumon:prod

echo -e "\n4️⃣ Waiting for container to start..."
sleep 5

echo -e "\n5️⃣ Testing RRD access..."
docker exec gpumon-prod python3 test_rrd_access.py

echo -e "\n✅ Container started with host user permissions!"
echo "🌐 Access at: http://localhost:8090"
echo "👤 Running as user: $CURRENT_USER (UID: $CURRENT_UID)"
