#!/bin/bash

echo "🚀 DEPLOYING GPU MONITOR WITH PRIVILEGED ACCESS"
echo "==============================================="

echo -e "\n1️⃣ Stopping any existing containers..."
docker stop gpumon-prod gpumon-app-prod-privileged 2>/dev/null || true
docker rm gpumon-prod gpumon-app-prod-privileged 2>/dev/null || true

echo -e "\n2️⃣ Building privileged container..."
docker build -f Dockerfile.prod.privileged -t gpumon:prod-privileged .

echo -e "\n3️⃣ Starting container with privileged access..."
docker run -d \
  --name gpumon-prod-privileged \
  -p 8090:5000 \
  --privileged \
  --cap-add=ALL \
  --security-opt seccomp:unconfined \
  -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro \
  -v /var/log/gpumon:/app/logs \
  --restart unless-stopped \
  gpumon:prod-privileged

echo -e "\n4️⃣ Waiting for container to start..."
sleep 5

echo -e "\n5️⃣ Checking container status..."
docker ps | grep gpumon-prod-privileged

echo -e "\n6️⃣ Testing RRD access with privileged container..."
docker exec gpumon-prod-privileged python3 test_rrd_access.py

echo -e "\n✅ Privileged container deployed!"
echo "🌐 Access at: http://localhost:8090"
echo "🔒 Container running with elevated privileges for RRD access"
