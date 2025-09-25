#!/bin/bash

echo "🔍 SEARCHING FOR RRD FILES ON YOUR SYSTEM"
echo "========================================="

echo -e "\n1️⃣ Common RRD locations:"
echo "---------------------------"

# Check common RRD locations
RRD_PATHS=(
    "/opt/docker/volumes/docker-observium_config/_data/rrd"
    "/var/lib/ganglia/rrds"
    "/var/lib/ganglia"
    "/opt/observium/rrd"
    "/opt/observium/rrd"
    "/var/lib/observium/rrd"
    "/opt/docker/observium/rrd"
    "/opt/docker/volumes/observium_config/_data/rrd"
    "/opt/docker/volumes/observium/_data/rrd"
    "/opt/docker/volumes/observium-rrd/_data"
    "/opt/docker/volumes/observium-rrd/_data/rrd"
    "/var/lib/docker/volumes/docker-observium_config/_data/rrd"
    "/var/lib/docker/volumes/observium_config/_data/rrd"
    "/var/lib/docker/volumes/observium/_data/rrd"
)

for path in "${RRD_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "✅ Found: $path"
        echo "   Contents:"
        ls -la "$path" | head -3
        echo ""
    else
        echo "❌ Not found: $path"
    fi
done

echo -e "\n2️⃣ Searching for .rrd files in common locations:"
echo "-------------------------------------------------"
find /opt -name "*.rrd" 2>/dev/null | head -10
find /var/lib -name "*.rrd" 2>/dev/null | head -10
find /home -name "*.rrd" 2>/dev/null | head -10

echo -e "\n3️⃣ Checking Docker volumes:"
echo "----------------------------"
docker volume ls | grep -i observium || echo "No observium volumes found"
docker volume ls | grep -i rrd || echo "No rrd volumes found"

echo -e "\n4️⃣ Checking running containers for RRD mounts:"
echo "------------------------------------------------"
docker ps --format "table {{.Names}}\t{{.Mounts}}" | grep -i rrd || echo "No containers with RRD mounts found"

echo -e "\n5️⃣ Checking for any .rrd files in the system:"
echo "-----------------------------------------------"
sudo find / -name "*.rrd" 2>/dev/null | head -10 || echo "No .rrd files found or permission denied"

echo -e "\n✅ RRD search complete!"
echo "📝 Look for paths that contain .rrd files above"
