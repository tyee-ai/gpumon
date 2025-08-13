#!/bin/bash

echo "🔧 FIXING RRD ACCESS ISSUE"
echo "=========================="

echo -e "\n1️⃣ Stopping existing container..."
docker stop gpumon-prod 2>/dev/null || true
docker rm gpumon-prod 2>/dev/null || true

echo -e "\n2️⃣ Checking host RRD directory..."
if [ -d "/opt/docker/volumes/docker-observium_config/_data/rrd" ]; then
    echo "✅ RRD directory exists on host"
    echo "📁 Contents:"
    ls -la /opt/docker/volumes/docker-observium_config/_data/rrd | head -5
else
    echo "❌ RRD directory not found on host!"
    echo "Expected path: /opt/docker/volumes/docker-observium_config/_data/rrd"
    exit 1
fi

echo -e "\n3️⃣ Checking host file permissions..."
ls -la /opt/docker/volumes/docker-observium_config/_data/rrd | head -3

echo -e "\n4️⃣ Rebuilding container with proper RRD access..."
docker build -f Dockerfile.prod -t gpumon:prod .

echo -e "\n5️⃣ Starting container with correct volume mount..."
docker run -d \
  --name gpumon-prod \
  -p 8090:5000 \
  -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro \
  --restart unless-stopped \
  gpumon:prod

echo -e "\n6️⃣ Waiting for container to start..."
sleep 5

echo -e "\n7️⃣ Testing RRD access..."
docker exec gpumon-prod python3 test_rrd_access.py

echo -e "\n✅ Container should now have RRD access!"
echo "🌐 Test at: http://localhost:8090"
