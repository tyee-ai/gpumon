#!/bin/bash
echo "🚀 GPU Monitoring Production Host Deployment"
echo "==========================================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "🔧 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Install/update dependencies
echo "📥 Installing/updating dependencies..."
pip install -r requirements.txt

# Set production environment
export RRD_DATA_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
export FLASK_ENV="production"
export FLASK_DEBUG="0"

echo "✅ Environment configured:"
echo "   RRD_DATA_PATH: $RRD_DATA_PATH"
echo "   FLASK_ENV: $FLASK_ENV"
echo "   FLASK_DEBUG: $FLASK_DEBUG"

echo ""
echo "🌐 Starting GPU Monitoring Web Application..."
echo "📊 Dashboard will be available at: http://192.168.1.247:8090"
echo "📊 API endpoint: http://192.168.1.247:8090/api/analysis"
echo ""
echo "Press Ctrl+C to stop the application"

# Start the web application
python web_app.py
