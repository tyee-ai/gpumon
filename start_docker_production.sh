#!/bin/bash

echo "🚀 Starting GPU Monitor in Docker (PRODUCTION MODE)"
echo "=================================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Stop any existing production containers
echo "🛑 Stopping existing production containers..."
docker-compose -f docker-compose.production.yml down

# Build and start the application with production data
echo "🔨 Building and starting GPU Monitor with PRODUCTION RRD data..."
docker-compose -f docker-compose.production.yml up --build -d

echo ""
echo "🎉 GPU Monitor is starting up in Docker (PRODUCTION MODE)!"
echo ""
echo "📱 Access the dashboard at: http://localhost:8092"
echo ""
echo "📊 Production Features:"
echo "  • Using REAL RRD data from /opt/docker/volumes/docker-observium_config/_data/rrd"
echo "  • Should find 516+ devices (not just test data)"
echo "  • Full production analysis capabilities"
echo "  • Site selection (DFW2 with 10.4.*.* subnet)"
echo "  • Date range selection"
echo "  • Alert type filtering (Throttled, Thermally Failed, Both)"
echo ""
echo "🛑 To stop the application:"
echo "   docker-compose -f docker-compose.production.yml down"
echo ""
echo "📝 To view logs:"
echo "   docker-compose -f docker-compose.production.yml logs -f gpumon"
echo ""
echo "🔍 To check container status:"
echo "   docker-compose -f docker-compose.production.yml ps"
