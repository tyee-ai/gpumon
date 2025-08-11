#!/bin/bash

echo "🔧 FIXING RRD ACCESS FOR WWW-DATA USER (UID 532)"
echo "================================================="

echo -e "\n1️⃣ Stopping existing container..."
docker stop gpumon-prod 2>/dev/null || true
docker rm gpumon-prod 2>/dev/null || true

echo -e "\n2️⃣ Building container..."
docker build -f Dockerfile.prod -t gpumon:prod .

echo -e "\n3️⃣ Starting container as www-data user (UID 532)..."
docker run -d \
  --name gpumon-prod \
  -p 8090:5000 \
  --user "532:532" \
  -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro \
  --restart unless-stopped \
  gpumon:prod

echo -e "\n4️⃣ Waiting for container to start..."
sleep 5

echo -e "\n5️⃣ Verifying container is running as www-data..."
docker exec gpumon-prod whoami 2>/dev/null || echo "Cannot check user"
docker exec gpumon-prod id 2>/dev/null || echo "Cannot check user ID"

echo -e "\n6️⃣ Testing RRD access..."
echo "Testing /app/data access:"
docker exec gpumon-prod ls -la /app/data 2>/dev/null || echo "❌ Cannot access /app/data"

echo -e "\nTesting for .rrd files:"
docker exec gpumon-prod find /app/data -name "*.rrd" 2>/dev/null | head -5 || echo "❌ No .rrd files found"

echo -e "\n7️⃣ Running RRD access test script..."
docker exec gpumon-prod python3 test_rrd_access.py 2>/dev/null || echo "❌ Cannot run test script"

echo -e "\n✅ Container should now have proper RRD access!"
echo "🌐 Access at: http://localhost:8090"
echo "👤 Running as user: www-data (UID: 532)"
echo ""
echo "🔍 If RRD access works, try running an analysis in the web UI"
