#!/bin/bash

echo "🔧 COMPLETE RRD ACCESS FIX"
echo "=========================="

echo -e "\n1️⃣ STOPPING ALL EXISTING CONTAINERS..."
docker stop $(docker ps -q --filter "name=gpumon") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=gpumon") 2>/dev/null || true

echo -e "\n2️⃣ CHECKING RRD PATH WITH SUDO..."
RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"

if sudo [ -d "$RRD_PATH" ]; then
    OWNER=$(sudo stat -c "%U" "$RRD_PATH")
    UID=$(sudo stat -c "%u" "$RRD_PATH")
    GID=$(sudo stat -c "%g" "$RRD_PATH")
    
    echo "✅ RRD path accessible with sudo"
    echo "Owner: $OWNER (UID: $UID, GID: $GID)"
    
    echo -e "\n3️⃣ BUILDING CONTAINER..."
    docker build -f Dockerfile.prod -t gpumon:prod .
    
    echo -e "\n4️⃣ TRYING APPROACH 1: Run with RRD owner permissions..."
    docker run -d \
      --name gpumon-prod \
      -p 8090:5000 \
      --user "$UID:$GID" \
      -v "$RRD_PATH:/app/data:ro" \
      --restart unless-stopped \
      gpumon:prod
    
    echo "Waiting for container to start..."
    sleep 5
    
    echo "Testing RRD access..."
    if docker exec gpumon-prod ls /app/data >/dev/null 2>&1; then
        echo "✅ Approach 1 SUCCESS! Container can access RRD files"
        docker exec gpumon-prod python3 test_rrd_access.py
        echo -e "\n🎉 RRD access fixed! Test analysis at: http://localhost:8090"
        exit 0
    else
        echo "❌ Approach 1 failed, trying next approach..."
        docker stop gpumon-prod && docker rm gpumon-prod
    fi
    
    echo -e "\n5️⃣ TRYING APPROACH 2: Run with privileged access..."
    docker run -d \
      --name gpumon-prod \
      -p 8090:5000 \
      --privileged \
      --cap-add=ALL \
      -v "$RRD_PATH:/app/data:ro" \
      --restart unless-stopped \
      gpumon:prod
    
    echo "Waiting for container to start..."
    sleep 5
    
    echo "Testing RRD access..."
    if docker exec gpumon-prod ls /app/data >/dev/null 2>&1; then
        echo "✅ Approach 2 SUCCESS! Container can access RRD files"
        docker exec gpumon-prod python3 test_rrd_access.py
        echo -e "\n🎉 RRD access fixed with privileged access! Test analysis at: http://localhost:8090"
        exit 0
    else
        echo "❌ Approach 2 failed, trying next approach..."
        docker stop gpumon-prod && docker rm gpumon-prod
    fi
    
    echo -e "\n6️⃣ TRYING APPROACH 3: Run as root with volume permissions..."
    docker run -d \
      --name gpumon-prod \
      -p 8090:5000 \
      -v "$RRD_PATH:/app/data:ro" \
      --restart unless-stopped \
      gpumon:prod
    
    echo "Waiting for container to start..."
    sleep 5
    
    echo "Testing RRD access..."
    if docker exec gpumon-prod ls /app/data >/dev/null 2>&1; then
        echo "✅ Approach 3 SUCCESS! Container can access RRD files"
        docker exec gpumon-prod python3 test_rrd_access.py
        echo -e "\n🎉 RRD access fixed! Test analysis at: http://localhost:8090"
        exit 0
    else
        echo "❌ All approaches failed"
        echo "Please check the RRD path and permissions manually"
        exit 1
    fi
    
else
    echo "❌ RRD path not accessible: $RRD_PATH"
    echo "Please verify the path is correct and accessible with sudo"
    exit 1
fi
