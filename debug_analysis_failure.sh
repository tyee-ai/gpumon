#!/bin/bash

echo "🐛 COMPREHENSIVE ANALYSIS FAILURE DEBUGGING"
echo "=========================================="

echo -e "\n1️⃣ CURRENT CONTAINER STATUS:"
echo "-------------------------------"
docker ps | grep gpumon || echo "❌ No gpumon containers running"

echo -e "\n2️⃣ CONTAINER LOGS (last 30 lines):"
echo "-------------------------------------"
docker logs gpumon-prod --tail 30 2>/dev/null || echo "❌ Cannot access container logs"

echo -e "\n3️⃣ TESTING RRD ACCESS STEP BY STEP:"
echo "-------------------------------------"
echo "Step 1: Can container access /app/data?"
docker exec gpumon-prod ls -la /app/data 2>/dev/null || echo "❌ Cannot access /app/data"

echo -e "\nStep 2: Are there .rrd files?"
docker exec gpumon-prod find /app/data -name "*.rrd" 2>/dev/null | head -5 || echo "❌ No .rrd files found"

echo -e "\nStep 3: Can container read a specific .rrd file?"
RRD_FILE=$(docker exec gpumon-prod find /app/data -name "*.rrd" 2>/dev/null | head -1)
if [ -n "$RRD_FILE" ]; then
    echo "Found RRD file: $RRD_FILE"
    docker exec gpumon-prod ls -la "$RRD_FILE" 2>/dev/null || echo "❌ Cannot read RRD file"
else
    echo "❌ No RRD files found to test"
fi

echo -e "\n4️⃣ TESTING RRDTOOL FUNCTIONALITY:"
echo "-----------------------------------"
echo "Testing rrdtool version:"
docker exec gpumon-prod rrdtool --version 2>/dev/null || echo "❌ rrdtool not available"

echo -e "\nTesting rrdtool info command:"
if [ -n "$RRD_FILE" ]; then
    docker exec gpumon-prod rrdtool info "$RRD_FILE" 2>/dev/null | head -5 || echo "❌ Cannot read RRD file with rrdtool"
else
    echo "Skipping rrdtool test - no RRD files found"
fi

echo -e "\n5️⃣ TESTING PYTHON SCRIPT EXECUTION:"
echo "-------------------------------------"
echo "Testing if gpu_monitor.py exists:"
docker exec gpumon-prod ls -la gpu_monitor.py 2>/dev/null || echo "❌ gpu_monitor.py not found"

echo -e "\nTesting gpu_monitor.py execution:"
docker exec gpumon-prod python3 gpu_monitor.py --help 2>/dev/null || echo "❌ gpu_monitor.py execution failed"

echo -e "\n6️⃣ TESTING API ENDPOINT DIRECTLY:"
echo "-----------------------------------"
echo "Testing /api/analysis endpoint:"
curl -s "http://localhost:8090/api/analysis?site=DFW2&start_date=2025-07-01&end_date=2025-08-11&alert_type=both" | head -20

echo -e "\n7️⃣ CHECKING CONTAINER USER AND PERMISSIONS:"
echo "---------------------------------------------"
echo "Container user:"
docker exec gpumon-prod whoami 2>/dev/null || echo "Cannot check user"

echo -e "\nContainer user ID:"
docker exec gpumon-prod id 2>/dev/null || echo "Cannot check user ID"

echo -e "\n8️⃣ TESTING HOST PERMISSIONS:"
echo "-------------------------------"
RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
echo "Host RRD path permissions:"
ls -ld "$RRD_PATH" 2>/dev/null || echo "Cannot check host permissions"

echo -e "\nHost RRD directory contents:"
ls -la "$RRD_PATH" | head -5 2>/dev/null || echo "Cannot list host RRD contents"

echo -e "\n9️⃣ TESTING WITH SUDO ACCESS:"
echo "-------------------------------"
if sudo [ -d "$RRD_PATH" ]; then
    echo "✅ Path accessible with sudo"
    echo "RRD files count: $(sudo find "$RRD_PATH" -name "*.rrd" | wc -l)"
    echo "Sample RRD file:"
    sudo find "$RRD_PATH" -name "*.rrd" | head -1
else
    echo "❌ Path not accessible even with sudo"
fi

echo -e "\n🔧 RECOMMENDED ACTIONS:"
echo "========================"
echo "1. Check container logs for specific error messages"
echo "2. Verify RRD files are actually .rrd files (not symlinks)"
echo "3. Test rrdtool commands manually in container"
echo "4. Check if gpu_monitor.py has all required dependencies"
echo "5. Verify the analysis API endpoint is working"

echo -e "\n✅ Debugging complete!"
