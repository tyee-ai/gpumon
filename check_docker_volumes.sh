#!/bin/bash

echo "🐳 CHECKING DOCKER VOLUMES AND CONTAINERS"
echo "========================================="

echo -e "\n1️⃣ All Docker volumes:"
echo "------------------------"
docker volume ls

echo -e "\n2️⃣ All running containers:"
echo "----------------------------"
docker ps -a

echo -e "\n3️⃣ Checking /opt/docker directory:"
echo "-----------------------------------"
if [ -d "/opt/docker" ]; then
    echo "✅ /opt/docker exists"
    echo "Contents:"
    ls -la /opt/docker/
    
    if [ -d "/opt/docker/volumes" ]; then
        echo -e "\n✅ /opt/docker/volumes exists"
        echo "Contents:"
        ls -la /opt/docker/volumes/
    else
        echo "❌ /opt/docker/volumes does not exist"
    fi
else
    echo "❌ /opt/docker does not exist"
fi

echo -e "\n4️⃣ Checking /var/lib/docker directory:"
echo "----------------------------------------"
if [ -d "/var/lib/docker" ]; then
    echo "✅ /var/lib/docker exists"
    if [ -d "/var/lib/docker/volumes" ]; then
        echo "✅ /var/lib/docker/volumes exists"
        echo "Contents:"
        ls -la /var/lib/docker/volumes/ | head -10
    else
        echo "❌ /var/lib/docker/volumes does not exist"
    fi
else
    echo "❌ /var/lib/docker does not exist"
fi

echo -e "\n5️⃣ Searching for any observium-related directories:"
echo "---------------------------------------------------"
find /opt -name "*observium*" -type d 2>/dev/null | head -10
find /var/lib -name "*observium*" -type d 2>/dev/null | head -10

echo -e "\n✅ Docker volumes check complete!"
