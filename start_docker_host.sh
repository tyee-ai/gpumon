#!/bin/bash

echo "🚀 Starting GPU Monitor in Docker (HOST MODE)"
echo "=============================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Stop any existing host containers
echo "🛑 Stopping existing host containers..."
docker-compose -f docker-compose.host.yml down

# Build and start the application with host networking
echo "🔨 Building and starting GPU Monitor with HOST networking..."
docker-compose -f docker-compose.host.yml up --build -d

echo ""
echo "🎉 GPU Monitor is starting up in Docker (HOST MODE)!"
echo ""
echo "📱 Access the dashboard at: http://localhost:8090"
echo ""
echo "📊 Host Mode Features:"
echo "  • Using HOST networking (bypasses Docker network restrictions)"
echo "  • Direct access to production RRD data from /opt/docker/volumes/docker-observium_config/_data/rrd"
echo "  • Should find 516+ devices (full production data)"
echo "  • Full production analysis capabilities"
echo ""
echo "🛑 To stop the application:"
echo "   docker-compose -f docker-compose.host.yml down"
echo ""
echo "📝 To view logs:"
echo "   docker-compose -f docker-compose.host.yml logs -f gpumon"
echo ""
echo "🔍 To check container status:"
echo "   docker-compose -f docker-compose.host.yml ps"
