#!/bin/bash

echo "🔍 TESTING ANALYSIS ERROR DETAILS"
echo "================================="

echo -e "\n1️⃣ Checking container logs for analysis errors..."
echo "---------------------------------------------------"
docker logs gpumon-prod | grep -i "error\|exception\|fail" | tail -10

echo -e "\n2️⃣ Testing API endpoint directly..."
echo "-------------------------------------"
echo "Testing /api/analysis endpoint..."
curl -s "http://localhost:8090/api/analysis?site=DFW2&start_date=2025-07-01&end_date=2025-08-11&alert_type=both" | head -20

echo -e "\n3️⃣ Testing gpu_monitor.py directly in container..."
echo "---------------------------------------------------"
docker exec gpumon-prod python3 -c "
import subprocess
import sys

try:
    result = subprocess.run(['python3', 'gpu_monitor.py', '--help'], 
                          capture_output=True, text=True, timeout=10)
    print('✅ gpu_monitor.py runs successfully')
    print('Output:', result.stdout[:200])
except Exception as e:
    print('❌ gpu_monitor.py failed:', e)
"

echo -e "\n4️⃣ Checking if gpu_monitor.py exists in container..."
echo "-----------------------------------------------------"
docker exec gpumon-prod ls -la gpu_monitor.py 2>/dev/null || echo "❌ gpu_monitor.py not found in container"

echo -e "\n5️⃣ Testing RRD access from Python..."
echo "--------------------------------------"
docker exec gpumon-prod python3 -c "
import os
import subprocess

print('Testing RRD directory access...')
if os.path.exists('/app/data'):
    print('✅ /app/data exists')
    try:
        files = os.listdir('/app/data')
        print(f'✅ Directory contains {len(files)} items')
        if files:
            print(f'First 5 items: {files[:5]}')
    except PermissionError:
        print('❌ Permission denied accessing /app/data')
    except Exception as e:
        print(f'❌ Error accessing /app/data: {e}')
else:
    print('❌ /app/data does not exist')

print('\\nTesting rrdtool command...')
try:
    result = subprocess.run(['rrdtool', '--version'], 
                          capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        print('✅ rrdtool works')
    else:
        print('❌ rrdtool failed')
except Exception as e:
    print(f'❌ rrdtool error: {e}')
"

echo -e "\n✅ Analysis error testing complete!"
