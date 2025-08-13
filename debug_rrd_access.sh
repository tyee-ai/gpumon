#!/bin/bash

echo "🐛 COMPREHENSIVE RRD ACCESS DEBUGGING"
echo "====================================="

echo -e "\n1️⃣ CURRENT CONTAINER STATUS:"
echo "-------------------------------"
docker ps | grep gpumon || echo "❌ No gpumon containers running"

echo -e "\n2️⃣ CONTAINER LOGS (last 20 lines):"
echo "-------------------------------------"
docker logs gpumon-prod --tail 20 2>/dev/null || echo "❌ Cannot access container logs"

echo -e "\n3️⃣ CONTAINER VOLUME MOUNTS:"
echo "-----------------------------"
docker inspect gpumon-prod | grep -A 20 "Mounts" 2>/dev/null || echo "❌ Cannot inspect container"

echo -e "\n4️⃣ TESTING RRD ACCESS IN CONTAINER:"
echo "-------------------------------------"
echo "Testing /app/data access:"
docker exec gpumon-prod ls -la /app/data 2>/dev/null || echo "❌ Cannot access /app/data"

echo -e "\nTesting for .rrd files:"
docker exec gpumon-prod find /app/data -name "*.rrd" 2>/dev/null | head -5 || echo "❌ No .rrd files found"

echo -e "\n5️⃣ TESTING RRDTOOL IN CONTAINER:"
echo "----------------------------------"
docker exec gpumon-prod rrdtool --version 2>/dev/null || echo "❌ rrdtool not available"

echo -e "\n6️⃣ TESTING PYTHON SCRIPT ACCESS:"
echo "-----------------------------------"
docker exec gpumon-prod python3 test_rrd_access.py 2>/dev/null || echo "❌ Cannot run test script"

echo -e "\n7️⃣ CHECKING CONTAINER USER:"
echo "-----------------------------"
docker exec gpumon-prod whoami 2>/dev/null || echo "❌ Cannot check user"
docker exec gpumon-prod id 2>/dev/null || echo "❌ Cannot check user ID"

echo -e "\n8️⃣ TESTING HOST RRD ACCESS:"
echo "-----------------------------"
RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
if [ -d "$RRD_PATH" ]; then
    echo "✅ Host path exists: $RRD_PATH"
    echo "Permissions:"
    ls -ld "$RRD_PATH"
    echo "Contents (first 5 items):"
    ls -la "$RRD_PATH" | head -5
else
    echo "❌ Host path does not exist: $RRD_PATH"
fi

echo -e "\n9️⃣ TESTING WITH SUDO:"
echo "----------------------"
if sudo [ -d "$RRD_PATH" ]; then
    echo "✅ Path accessible with sudo"
    echo "Owner: $(sudo stat -c "%U:%G" "$RRD_PATH")"
    echo "UID/GID: $(sudo stat -c "%u:%g" "$RRD_PATH")"
    echo "RRD files count: $(sudo find "$RRD_PATH" -name "*.rrd" | wc -l)"
else
    echo "❌ Path not accessible even with sudo"
fi

echo -e "\n🔧 RECOMMENDED FIXES:"
echo "======================"
echo "1. If container user doesn't match RRD owner, run: ./fix_user_permissions.sh"
echo "2. If volume not mounted correctly, check docker run command"
echo "3. If rrdtool missing, rebuild container"
echo "4. If permissions still wrong, try: ./run_privileged.sh"

echo -e "\n✅ Debugging complete!"
