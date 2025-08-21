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

# Check for docker-compose or docker compose
DOCKER_COMPOSE_CMD=""
if command -v docker-compose > /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ Neither 'docker-compose' nor 'docker compose' found."
    echo "Please install docker-compose or ensure Docker Compose plugin is available."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo "🔧 Using: $DOCKER_COMPOSE_CMD"
echo ""

# Stop any existing containers
echo "🛑 Stopping existing containers..."
$DOCKER_COMPOSE_CMD down 2>/dev/null || true

# Build and start the application
echo "🔨 Building and starting GPU Monitor with HTTPS..."
$DOCKER_COMPOSE_CMD up --build -d

# Wait for the application to start
echo "⏳ Waiting for application to start..."
sleep 10

# Check if the application is running
if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
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
    $DOCKER_COMPOSE_CMD ps
    echo ""
    echo "📝 Logs: $DOCKER_COMPOSE_CMD logs -f"
    echo "🛑 Stop: $DOCKER_COMPOSE_CMD down"
    echo ""
    echo "🔒 Your GPU Monitor is now secure with HTTPS!"
else
    echo "❌ Failed to start GPU Monitor. Check logs with:"
    echo "   $DOCKER_COMPOSE_CMD logs"
    exit 1
fi
