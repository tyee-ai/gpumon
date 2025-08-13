#!/bin/bash

echo "🌐 Starting GPU RRD Monitor Web Interface with RRD Data Path"
echo "=========================================================="
echo ""

# Export the RRD data path
export RRD_DATA_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
echo "✅ RRD_DATA_PATH set to: $RRD_DATA_PATH"
echo ""

# Check if the path exists
if [ ! -d "$RRD_DATA_PATH" ]; then
    echo "❌ RRD data path does not exist: $RRD_DATA_PATH"
    exit 1
fi

echo "✅ RRD data path exists and is accessible"
echo ""

# Start the web application
echo "🚀 Starting web application on http://192.168.1.247:8090"
echo ""

# Start in background with nohup
nohup python3 web_app.py > web_app.log 2>&1 &

# Get the process ID
WEB_APP_PID=$!
echo "✅ Web application started with PID: $WEB_APP_PID"
echo ""
echo "📱 Access the dashboard at: http://192.168.1.247:8090"
echo ""
echo "📊 Features:"
echo "  • Site selection (DFW2 with 10.4.*.* subnet)"
echo "  • Date range selection"
echo "  • Alert type filtering (Throttled, Thermally Failed, Both)"
echo "  • Real-time GPU analysis with RRD data access"
echo "  • Beautiful results display"
echo ""
echo "🛑 To stop the application:"
echo "   pkill -f 'python3 web_app.py'"
echo ""
echo "📝 To view logs:"
echo "   tail -f web_app.log"
echo ""
echo "🔍 To check if running:"
echo "   ps aux | grep web_app"
