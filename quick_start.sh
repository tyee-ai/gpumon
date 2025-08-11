#!/bin/bash

echo "🚀 GPU RRD Monitor - Quick Start"
echo "================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Check if image exists
if ! docker image inspect gpu-rrd-monitor > /dev/null 2>&1; then
    echo "🔨 Building Docker image..."
    docker build -t gpu-rrd-monitor .
    echo ""
fi

echo "🎯 Ready to run! Here are your options:"
echo ""

echo "1️⃣  Quick Analysis (Last Hour):"
echo "   docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14"
echo ""

echo "2️⃣  Full Analysis (Custom Date Range):"
echo "   docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14 --full --start-date 2024-08-01 --end-date 2024-08-09"
echo ""

echo "3️⃣  Test Different Site:"
echo "   docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 15"
echo ""

echo "💡 Tip: Replace the dates in option 2 with your desired range"
echo "💡 Tip: Change the site number in options 1, 2, and 3 as needed"
