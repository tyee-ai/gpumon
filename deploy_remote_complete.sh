#!/bin/bash
echo "🚀 GPU Monitoring Remote Host Complete Deployment"
echo "================================================"

echo ""
echo "📦 Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y python3-rrdtool curl

echo ""
echo "🔧 Setting up Python environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate

echo ""
echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

echo ""
echo "🧪 Testing GPU monitor script..."
python3 gpu_monitor.py --site 4 --help

echo ""
echo "✅ Deployment complete!"
echo "🌐 To start the web app:"
echo "   source venv/bin/activate"
echo "   export RRD_DATA_PATH=\"/path/to/your/rrd/data\""
echo "   python3 web_app.py"
echo ""
echo "📊 The web app will be available at: http://10.4.231.200:8090"
