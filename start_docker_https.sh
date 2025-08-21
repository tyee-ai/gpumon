#!/bin/bash
# GPU Monitor - Production HTTPS Deployment Script
# This script deploys GPU Monitor with HTTPS enabled

set -e

echo "🚀 GPU Monitor - Production HTTPS Deployment"
echo "============================================"

# Check if SSL certificates exist
if [ ! -f "./ssl/cert.pem" ] || [ ! -f "./ssl/key.pem" ]; then
    echo "❌ SSL certificates not found!"
    echo ""
    echo "🔒 Generating SSL certificates..."
    ./scripts/generate_ssl_certs.sh
    echo ""
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ docker-compose not found. Please install docker-compose and try again."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Build and start the application
echo "🔨 Building and starting GPU Monitor with HTTPS..."
docker-compose up --build -d

# Wait for the application to start
echo "⏳ Waiting for application to start..."
sleep 10

# Check if the application is running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "🎉 GPU Monitor is now running with HTTPS!"
    echo "========================================"
    echo ""
    echo "🌐 Access URLs:"
    echo "   HTTPS (Main): https://localhost:8443"
    echo "   HTTP (Fallback): http://localhost:8090"
    echo ""
    echo "🔒 SSL Status: Enabled"
    echo "📋 Certificate: Self-signed (valid for 1 year)"
    echo "⚠️  Note: Accept the certificate warning in your browser"
    echo ""
    echo "📊 Container Status:"
    docker-compose ps
    echo ""
    echo "📝 Logs: docker-compose logs -f"
    echo "🛑 Stop: docker-compose down"
    echo ""
    echo "🔒 Your GPU Monitor is now secure with HTTPS!"
else
    echo "❌ Failed to start GPU Monitor. Check logs with:"
    echo "   docker-compose logs"
    exit 1
fi
