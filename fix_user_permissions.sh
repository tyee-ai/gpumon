#!/bin/bash

echo "🔧 FIXING USER PERMISSIONS FOR RRD ACCESS"
echo "========================================="

echo -e "\n1️⃣ Finding the correct RRD path with sudo..."
RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"

if sudo [ -d "$RRD_PATH" ]; then
    echo "✅ RRD path exists: $RRD_PATH"
    
    # Get the owner and group of the RRD directory
    OWNER=$(sudo stat -c "%U" "$RRD_PATH")
    GROUP=$(sudo stat -c "%G" "$RRD_PATH")
    UID=$(sudo stat -c "%u" "$RRD_PATH")
    GID=$(sudo stat -c "%g" "$RRD_PATH")
    
    echo "📁 Directory owner: $OWNER:$GROUP (UID:$UID, GID:$GID)"
    
    echo -e "\n2️⃣ Stopping existing container..."
    docker stop gpumon-prod 2>/dev/null || true
    docker rm gpumon-prod 2>/dev/null || true
    
    echo -e "\n3️⃣ Building container with correct user..."
    docker build -f Dockerfile.prod -t gpumon:prod .
    
    echo -e "\n4️⃣ Starting container with user mapping..."
    docker run -d \
      --name gpumon-prod \
      -p 8090:5000 \
      --user "$UID:$GID" \
      -v /opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro \
      --restart unless-stopped \
      gpumon:prod
    
    echo -e "\n5️⃣ Waiting for container to start..."
    sleep 5
    
    echo -e "\n6️⃣ Testing RRD access..."
    docker exec gpumon-prod python3 test_rrd_access.py
    
    echo -e "\n✅ Container should now have proper RRD access!"
    echo "🌐 Access at: http://localhost:8090"
    echo "👤 Running as user: $OWNER (UID: $UID)"
    
else
    echo "❌ RRD path not found: $RRD_PATH"
    echo "Please run: ./find_rrd_sudo.sh to find the correct path"
fi
