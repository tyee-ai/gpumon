#!/bin/bash

echo "🌐 Starting GPU RRD Monitor Web Interface"
echo "========================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Build and start the web application
echo "🔨 Building and starting web application..."
docker-compose up --build -d

echo ""
echo "🎉 Web interface is starting up!"
echo ""
echo "📱 Access the dashboard at: http://localhost:5000"
echo ""
echo "📊 Features:"
echo "  • Site selection (DFW2 with 10.4.*.* subnet)"
echo "  • Date range selection"
echo "  • Alert type filtering (Throttled, Thermally Failed, Both)"
echo "  • Real-time GPU analysis"
echo "  • Beautiful results display"
echo ""
echo "🛑 To stop the application:"
echo "   docker-compose down"
echo ""
echo "📝 To view logs:"
echo "   docker-compose logs -f"
