#!/bin/bash
echo "🚀 Starting GPU Monitoring Web Application on Host"
echo "================================================"

# Set the correct RRD data path for host deployment
export RRD_DATA_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"

echo "✅ RRD_DATA_PATH set to: $RRD_DATA_PATH"
echo "🌐 Starting web app on port 8090..."
echo "📊 Access the dashboard at: http://localhost:8090"
echo ""

# Start the web application
python3 web_app.py
