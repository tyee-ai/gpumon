#!/bin/bash

# GPU Monitor Remote Deployment Script
# This script helps deploy the GPU Monitor to remote systems

echo "🚀 GPU Monitor Remote Deployment Script"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "web_app.py" ]; then
    echo "❌ Error: web_app.py not found. Please run this script from the gpumon directory."
    exit 1
fi

# Check Python version
echo "🐍 Checking Python version..."
python3 --version
if [ $? -ne 0 ]; then
    echo "❌ Error: Python3 not found. Please install Python 3.7+"
    exit 1
fi

# Check if required packages are installed
echo "📦 Checking required packages..."
python3 -c "import flask" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Flask not found. Installing..."
    pip3 install flask
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p /tmp/rrd_data
mkdir -p logs

# Set environment variables for local testing
export RRD_BASE_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
export FLASK_HOST="0.0.0.0"
export FLASK_PORT="8090"

echo "🔧 Environment variables set:"
echo "   RRD_BASE_PATH: $RRD_BASE_PATH"
echo "   FLASK_HOST: $FLASK_HOST"
echo "   FLASK_PORT: $FLASK_PORT"

# Test the web app
echo "🧪 Testing web app..."
python3 -m py_compile web_app.py
if [ $? -ne 0 ]; then
    echo "❌ Error: web_app.py has syntax errors"
    exit 1
fi

echo "✅ Web app syntax check passed"

# Start the web app
echo "🚀 Starting GPU Monitor web app..."
echo "   Access the app at: http://$(hostname -I | awk '{print $1}'):8090"
echo "   Health check: http://$(hostname -I | awk '{print $1}'):8090/api/health"
echo ""
echo "Press Ctrl+C to stop the web app"

# Start the web app in the foreground
python3 web_app.py
