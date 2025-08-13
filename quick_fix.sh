#!/bin/bash

echo "🚀 QUICK FIX FOR PORT 8090 CONFLICT"
echo "===================================="

echo -e "\n🧹 Cleaning up Docker environment..."
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker network prune -f 2>/dev/null || true

echo -e "\n🔧 Updating docker-compose.yml to use port 8091..."
sed -i 's/8090:5000/8091:5000/' docker-compose.yml

echo -e "\n✅ Port changed to 8091. Now you can run:"
echo "docker-compose up --build"
echo ""
echo "🌐 Access your GPU Monitor at: http://localhost:8091"
echo "   (or http://10.4.231.200:8091 on your remote host)"
