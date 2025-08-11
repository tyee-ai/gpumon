#!/bin/bash

echo "🧪 Starting GPU RRD Monitor Web Interface (Test Mode)"
echo "====================================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Create test RRD data directory
if [ ! -d "./test-rrd-data" ]; then
    echo "📁 Creating test RRD data directory..."
    mkdir -p ./test-rrd-data
    echo "✅ Created ./test-rrd-data directory"
fi

# Build and start the test application
echo "🔨 Building and starting test application..."
docker-compose -f docker-compose.test.yml up --build -d

echo ""
echo "🎉 Test web interface is starting up!"
echo ""
echo "📱 Access the dashboard at: http://localhost:5000"
echo ""
echo "⚠️  Note: This is TEST MODE - no real RRD data will be available"
echo "   The analysis will fail, but you can see the web interface"
echo ""
echo "🛑 To stop the test application:"
echo "   docker-compose -f docker-compose.test.yml down"
echo ""
echo "📝 To view logs:"
echo "   docker-compose -f docker-compose.test.yml logs -f"
echo ""
echo "🚀 To run with real data, use:"
echo "   ./setup_rrd_mount.sh"
echo "   ./start_web.sh"
