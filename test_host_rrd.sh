#!/bin/bash

echo "🔍 TESTING HOST RRD ACCESS"
echo "==========================="

RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"

echo -e "\n1️⃣ Checking if RRD path exists:"
if [ -d "$RRD_PATH" ]; then
    echo "✅ RRD directory exists: $RRD_PATH"
else
    echo "❌ RRD directory NOT found: $RRD_PATH"
    echo "Please verify the path is correct!"
    exit 1
fi

echo -e "\n2️⃣ Checking directory permissions:"
ls -ld "$RRD_PATH"

echo -e "\n3️⃣ Checking contents:"
ls -la "$RRD_PATH" | head -10

echo -e "\n4️⃣ Looking for .rrd files:"
find "$RRD_PATH" -name "*.rrd" | head -5

echo -e "\n5️⃣ Testing read access:"
if [ -r "$RRD_PATH" ]; then
    echo "✅ Directory is readable"
else
    echo "❌ Directory is NOT readable"
fi

echo -e "\n6️⃣ Checking if this is a Docker volume:"
docker volume ls | grep observium || echo "No Docker volume found with 'observium' in name"

echo -e "\n✅ Host RRD check complete!"
