#!/bin/bash

echo "🐳 Testing GPU RRD Monitor Docker Setup"
echo "======================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Build the image
echo "🔨 Building Docker image..."
if docker build -t gpu-rrd-monitor .; then
    echo "✅ Docker image built successfully"
else
    echo "❌ Failed to build Docker image"
    exit 1
fi

# Test basic functionality
echo "🧪 Testing basic functionality..."
if docker run --rm gpu-rrd-monitor --help; then
    echo "✅ Basic functionality test passed"
else
    echo "❌ Basic functionality test failed"
    exit 1
fi

echo ""
echo "🎉 Docker setup is working correctly!"
echo ""
echo "Next steps:"
echo "1. Run basic analysis:"
echo "   docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14"
echo ""
echo "2. Or use docker-compose:"
echo "   docker-compose run --rm gpu-rrd-monitor /rrd-data --site 14"
