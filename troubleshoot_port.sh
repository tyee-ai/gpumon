#!/bin/bash

echo "🔍 PORT 8090 TROUBLESHOOTING SCRIPT"
echo "====================================="

echo -e "\n1️⃣ Checking what processes are using port 8090:"
echo "----------------------------------------"
netstat -tlnp | grep :8090 2>/dev/null || echo "No process found with netstat"
echo ""

echo "2️⃣ Checking with ss command:"
echo "---------------------------"
ss -tlnp | grep :8090 2>/dev/null || echo "No process found with ss"
echo ""

echo "3️⃣ Checking Docker containers using port 8090:"
echo "--------------------------------------------"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 8090 2>/dev/null || echo "No Docker containers using port 8090"
echo ""

echo "4️⃣ Checking all Docker containers:"
echo "---------------------------------"
docker ps -a
echo ""

echo "5️⃣ Checking for any gpumon containers:"
echo "-------------------------------------"
docker ps -a | grep -i gpumon || echo "No gpumon containers found"
echo ""

echo "6️⃣ Checking Docker networks:"
echo "---------------------------"
docker network ls
echo ""

echo "7️⃣ Checking if port 8090 is in use by any service:"
echo "------------------------------------------------"
lsof -i :8090 2>/dev/null || echo "No process found with lsof"
echo ""

echo "8️⃣ Checking system services that might use port 8090:"
echo "--------------------------------------------------"
systemctl list-units --type=service | grep -i 8090 || echo "No systemd services found with port 8090"
echo ""

echo "9️⃣ Checking for any Python processes that might be using port 8090:"
echo "----------------------------------------------------------------"
ps aux | grep python | grep -v grep || echo "No Python processes found"
echo ""

echo "🔧 RECOMMENDED ACTIONS:"
echo "======================="
echo "1. Stop all Docker containers: docker stop \$(docker ps -q)"
echo "2. Remove all containers: docker rm \$(docker ps -aq)"
echo "3. Prune Docker system: docker system prune -f"
echo "4. Try using port 8091 instead: ./deploy_observium_alt.sh"
echo "5. Or manually specify a different port in docker-compose.yml"
