#!/bin/bash

echo "🔍 SEARCHING FOR RRD FILES WITH SUDO ACCESS"
echo "==========================================="

echo -e "\n1️⃣ Checking the expected path with sudo:"
echo "------------------------------------------"
RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"

if sudo [ -d "$RRD_PATH" ]; then
    echo "✅ Path exists: $RRD_PATH"
    echo "📁 Contents (with sudo):"
    sudo ls -la "$RRD_PATH" | head -10
    
    echo -e "\n🔍 Looking for .rrd files:"
    sudo find "$RRD_PATH" -name "*.rrd" | head -10
    
    echo -e "\n📊 Count of .rrd files:"
    sudo find "$RRD_PATH" -name "*.rrd" | wc -l
else
    echo "❌ Path does not exist: $RRD_PATH"
fi

echo -e "\n2️⃣ Checking alternative observium paths with sudo:"
echo "---------------------------------------------------"
ALTERNATIVE_PATHS=(
    "/opt/docker/volumes/observium_config/_data/rrd"
    "/opt/docker/volumes/observium/_data/rrd"
    "/opt/docker/volumes/observium-rrd/_data"
    "/var/lib/docker/volumes/docker-observium_config/_data/rrd"
    "/var/lib/docker/volumes/observium_config/_data/rrd"
    "/opt/observium/rrd"
    "/var/lib/observium/rrd"
)

for path in "${ALTERNATIVE_PATHS[@]}"; do
    if sudo [ -d "$path" ]; then
        echo "✅ Found: $path"
        echo "   Contents:"
        sudo ls -la "$path" | head -3
        echo ""
    fi
done

echo -e "\n3️⃣ Checking Docker volumes with sudo:"
echo "--------------------------------------"
sudo docker volume ls | grep -i observium || echo "No observium volumes found"

echo -e "\n4️⃣ Checking file permissions:"
echo "-------------------------------"
if sudo [ -d "$RRD_PATH" ]; then
    echo "Permissions for $RRD_PATH:"
    sudo ls -ld "$RRD_PATH"
    
    echo -e "\nOwner and group:"
    sudo stat -c "%U:%G" "$RRD_PATH"
fi

echo -e "\n✅ Sudo RRD search complete!"
echo "📝 Use the path that contains .rrd files for your Docker volume mount"
