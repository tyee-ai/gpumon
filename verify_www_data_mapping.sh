#!/bin/bash

echo "🔍 VERIFYING WWW-DATA USER MAPPING"
echo "=================================="

echo -e "\n1️⃣ Checking host www-data user:"
echo "--------------------------------"
if id www-data >/dev/null 2>&1; then
    echo "✅ www-data user exists on host"
    id www-data
else
    echo "❌ www-data user not found on host"
fi

echo -e "\n2️⃣ Checking UID 532 on host:"
echo "-------------------------------"
if getent passwd 532 >/dev/null 2>&1; then
    echo "✅ UID 532 exists on host"
    getent passwd 532
else
    echo "❌ UID 532 not found on host"
fi

echo -e "\n3️⃣ Checking RRD directory permissions:"
echo "----------------------------------------"
RRD_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
if [ -d "$RRD_PATH" ]; then
    echo "✅ RRD directory exists"
    ls -ld "$RRD_PATH"
    echo "Owner: $(stat -c "%U:%G" "$RRD_PATH")"
    echo "UID/GID: $(stat -c "%u:%g" "$RRD_PATH")"
else
    echo "❌ RRD directory not found: $RRD_PATH"
fi

echo -e "\n4️⃣ Testing container user mapping..."
echo "-------------------------------------"
echo "Creating test container to verify user mapping..."

docker run --rm --user "532:532" alpine:latest sh -c "
echo 'Container user info:'
whoami
id
echo 'Testing if we can access mounted directory...'
ls -la /tmp 2>/dev/null || echo 'Cannot access /tmp'
" 2>/dev/null || echo "❌ Test container failed"

echo -e "\n✅ User mapping verification complete!"
echo "📝 Use this information to configure the container correctly"
