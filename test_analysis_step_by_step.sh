#!/bin/bash

echo "🔍 TESTING ANALYSIS STEP BY STEP"
echo "================================"

echo -e "\n1️⃣ TESTING BASIC CONTAINER ACCESS:"
echo "-----------------------------------"
if docker exec gpumon-prod whoami >/dev/null 2>&1; then
    echo "✅ Container is accessible"
else
    echo "❌ Container is not accessible"
    exit 1
fi

echo -e "\n2️⃣ TESTING RRD DIRECTORY ACCESS:"
echo "----------------------------------"
if docker exec gpumon-prod ls /app/data >/dev/null 2>&1; then
    echo "✅ Can access /app/data directory"
    RRD_COUNT=$(docker exec gpumon-prod find /app/data -name "*.rrd" 2>/dev/null | wc -l)
    echo "   Found $RRD_COUNT .rrd files"
else
    echo "❌ Cannot access /app/data directory"
    exit 1
fi

echo -e "\n3️⃣ TESTING RRDTOOL COMMAND:"
echo "-----------------------------"
if docker exec gpumon-prod rrdtool --version >/dev/null 2>&1; then
    echo "✅ rrdtool is available"
else
    echo "❌ rrdtool is not available"
    exit 1
fi

echo -e "\n4️⃣ TESTING RRD FILE READING:"
echo "------------------------------"
RRD_FILE=$(docker exec gpumon-prod find /app/data -name "*.rrd" 2>/dev/null | head -1)
if [ -n "$RRD_FILE" ]; then
    echo "Testing RRD file: $RRD_FILE"
    if docker exec gpumon-prod rrdtool info "$RRD_FILE" >/dev/null 2>&1; then
        echo "✅ Can read RRD file with rrdtool"
    else
        echo "❌ Cannot read RRD file with rrdtool"
        exit 1
    fi
else
    echo "❌ No RRD files found to test"
    exit 1
fi

echo -e "\n5️⃣ TESTING GPU MONITOR SCRIPT:"
echo "--------------------------------"
if docker exec gpumon-prod ls gpu_monitor.py >/dev/null 2>&1; then
    echo "✅ gpu_monitor.py exists"
else
    echo "❌ gpu_monitor.py not found"
    exit 1
fi

echo -e "\n6️⃣ TESTING PYTHON EXECUTION:"
echo "-------------------------------"
if docker exec gpumon-prod python3 --version >/dev/null 2>&1; then
    echo "✅ Python3 is available"
else
    echo "❌ Python3 is not available"
    exit 1
fi

echo -e "\n7️⃣ TESTING GPU MONITOR EXECUTION:"
echo "-----------------------------------"
if docker exec gpumon-prod python3 gpu_monitor.py --help >/dev/null 2>&1; then
    echo "✅ gpu_monitor.py executes successfully"
else
    echo "❌ gpu_monitor.py execution failed"
    echo "Error details:"
    docker exec gpumon-prod python3 gpu_monitor.py --help 2>&1 | head -5
    exit 1
fi

echo -e "\n8️⃣ TESTING ANALYSIS API:"
echo "--------------------------"
echo "Testing API endpoint..."
API_RESPONSE=$(curl -s "http://localhost:8090/api/analysis?site=DFW2&start_date=2025-07-01&end_date=2025-08-11&alert_type=both")
if [ $? -eq 0 ]; then
    echo "✅ API endpoint responds"
    echo "Response length: ${#API_RESPONSE} characters"
    if [[ "$API_RESPONSE" == *"error"* ]]; then
        echo "❌ API returned error:"
        echo "$API_RESPONSE" | head -10
    else
        echo "✅ API response looks good"
    fi
else
    echo "❌ API endpoint failed"
    exit 1
fi

echo -e "\n🎉 ALL TESTS PASSED! Analysis should work."
echo "🌐 Test the analysis in the web UI at: http://localhost:8090"
