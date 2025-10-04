#!/bin/bash

# Test script to check remote node configuration
# Usage: ./test-remote-config.sh <remote-ip>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <remote-ip>"
    echo "Example: $0 10.9.231.200"
    exit 1
fi

REMOTE_IP=$1
echo "Testing remote node: $REMOTE_IP"

# Test 1: Check if SEA1 is in the code
echo "1. Checking if SEA1 is in site_config.py..."
ssh root@$REMOTE_IP "cd /root/gpumon && grep -q 'SEA1' site_config.py && echo '✅ SEA1 found in code' || echo '❌ SEA1 NOT found in code'"

# Test 2: Check API response
echo "2. Checking API response..."
ssh root@$REMOTE_IP "curl -s http://localhost:8090/api/sites | grep -q 'SEA1' && echo '✅ SEA1 found in API' || echo '❌ SEA1 NOT found in API'"

# Test 3: Check container status
echo "3. Checking container status..."
ssh root@$REMOTE_IP "docker ps | grep gpumon-remote && echo '✅ Container running' || echo '❌ Container not running'"

# Test 4: Check container logs for errors
echo "4. Checking container logs..."
ssh root@$REMOTE_IP "docker logs gpumon-remote 2>&1 | tail -5"
