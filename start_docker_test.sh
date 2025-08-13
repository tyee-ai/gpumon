#!/bin/bash

echo "🧪 Starting GPU Monitor in Docker (TEST MODE)"
echo "============================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.test.yml down

# Build and start the application with test data
echo "🔨 Building and starting GPU Monitor with test data..."
docker-compose -f docker-compose.test.yml up --build -d

echo ""
echo "🎉 GPU Monitor is starting up in Docker (TEST MODE)!"
echo ""
echo "📱 Access the dashboard at: http://localhost:8090"
echo ""
echo "📊 Test Features:"
echo "  • Using test RRD data from ./test-rrd-data"
echo "  • Development mode with debug enabled"
echo "  • Site selection (DFW2 with 10.4.*.* subnet)"
echo "  • Date range selection"
echo "  • Alert type filtering (Throttled, Thermally Failed, Both)"
echo ""
echo "🛑 To stop the application:"
echo "   docker-compose -f docker-compose.test.yml down"
echo ""
echo "📝 To view logs:"
echo "   docker-compose -f docker-compose.test.yml logs -f gpumon"
echo ""
echo "🔍 To check container status:"
echo "   docker-compose -f docker-compose.test.yml ps"
