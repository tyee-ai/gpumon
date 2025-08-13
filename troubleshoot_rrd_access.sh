#!/bin/bash

echo "🔍 RRD ACCESS TROUBLESHOOTING SCRIPT"
echo "====================================="

echo -e "\n1️⃣ Checking if the container is running:"
echo "----------------------------------------"
docker ps | grep gpumon-prod || echo "❌ gpumon-prod container not found!"

echo -e "\n2️⃣ Checking container logs for errors:"
echo "----------------------------------------"
docker logs gpumon-prod --tail 20

echo -e "\n3️⃣ Checking if RRD directory is mounted:"
echo "------------------------------------------"
docker exec gpumon-prod ls -la /app/data 2>/dev/null || echo "❌ /app/data not accessible"

echo -e "\n4️⃣ Checking RRD file permissions:"
echo "-----------------------------------"
docker exec gpumon-prod ls -la /app/data/ | head -10 2>/dev/null || echo "❌ Cannot list /app/data contents"

echo -e "\n5️⃣ Checking if rrdtool is working in container:"
echo "------------------------------------------------"
docker exec gpumon-prod rrdtool --version 2>/dev/null || echo "❌ rrdtool not available"

echo -e "\n6️⃣ Testing RRD file access:"
echo "-----------------------------"
docker exec gpumon-prod find /app/data -name "*.rrd" | head -5 2>/dev/null || echo "❌ No .rrd files found"

echo -e "\n7️⃣ Checking container volume mounts:"
echo "-------------------------------------"
docker inspect gpumon-prod | grep -A 10 "Mounts" || echo "❌ Cannot inspect container"

echo -e "\n8️⃣ Testing Python script access:"
echo "---------------------------------"
docker exec gpumon-prod python3 test_rrd_access.py 2>/dev/null || echo "❌ Cannot run test script"

echo -e "\n🔧 RECOMMENDED FIXES:"
echo "======================"
echo "1. Check if RRD path exists on host: ls -la /opt/docker/volumes/docker-observium_config/_data/rrd"
echo "2. Verify container is running as root: docker exec gpumon-prod whoami"
echo "3. Check host file permissions: ls -la /opt/docker/volumes/docker-observium_config/_data/rrd"
echo "4. Restart container with proper volume mount:"
echo "   docker stop gpumon-prod && docker rm gpumon-prod"
echo "   docker run -d --name gpumon-prod -p 8090:5000 -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro gpumon:prod"
