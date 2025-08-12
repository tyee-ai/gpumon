#!/bin/bash

# Script to fix port 8090 conflict on remote host
# Run this on your remote host (10.4.231.200)

echo "🔍 Checking what's using port 8090..."

# Check what's using port 8090
echo "Port 8090 usage:"
netstat -tlnp | grep :8090 || echo "No process found using netstat"

echo -e "\nAlternative check with ss:"
ss -tlnp | grep :8090 || echo "No process found using ss"

echo -e "\n🔍 Checking Docker containers:"
docker ps -a | grep -E "(8090|gpumon)"

echo -e "\n🧹 Cleaning up existing containers..."
# Stop and remove any existing gpumon containers
docker stop $(docker ps -q --filter "name=gpumon") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=gpumon") 2>/dev/null || true

echo -e "\n🔍 Checking for any remaining containers using port 8090:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 8090 || echo "No containers using port 8090"

echo -e "\n✅ Port 8090 should now be free!"
echo "You can now run: ./deploy_observium.sh"
