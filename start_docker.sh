#!/bin/bash

echo "🐳 Starting GPU Monitor in Docker"
echo "================================="
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
docker-compose down

# Build and start the application
echo "🔨 Building and starting GPU Monitor..."
docker-compose up --build -d

echo ""
echo "🎉 GPU Monitor is starting up in Docker!"
echo ""
echo "📱 Access the dashboard at: http://localhost:8090"
echo ""
echo "📊 Features:"
echo "  • Site selection (DFW2 with 10.4.*.* subnet)"
echo "  • Date range selection"
echo "  • Alert type filtering (Throttled, Thermally Failed, Both)"
echo "  • Real-time GPU analysis with accurate duration calculations"
echo "  • Color-coded results display"
echo ""
echo "🛑 To stop the application:"
echo "   docker-compose down"
echo ""
echo "📝 To view logs:"
echo "   docker-compose logs -f gpumon"
echo ""
echo "🔍 To check container status:"
echo "   docker-compose ps"
