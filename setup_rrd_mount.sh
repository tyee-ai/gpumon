#!/bin/bash

echo "🔧 Setting up RRD Data Mount for GPU Monitor"
echo "============================================="
echo ""

# Check if the rrd-data directory exists
if [ ! -d "./rrd-data" ]; then
    echo "�� Creating rrd-data directory..."
    mkdir -p ./rrd-data
    echo "✅ Created ./rrd-data directory"
else
    echo "✅ ./rrd-data directory already exists"
fi

echo ""
echo "🔗 You need to link your RRD data to the ./rrd-data directory"
echo ""
echo "Option 1: Create a symbolic link (recommended)"
echo "   ln -s /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd ./rrd-data"
echo ""
echo "Option 2: Copy the data (if you have space)"
echo "   cp -r /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd/* ./rrd-data/"
echo ""
echo "Option 3: Mount from a different location"
echo "   ln -s /your/actual/rrd/path ./rrd-data"
echo ""
echo "After setting up the RRD data, run:"
echo "   ./start_web.sh"
echo ""
echo "The web interface will be available at: http://localhost:5000"
