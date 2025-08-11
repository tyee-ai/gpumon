# 🚀 GPU Monitoring - Production Host Deployment Guide

## 📋 Prerequisites
- Python 3.8+ installed
- Access to RRD data directory
- Git repository cloned

## 🔧 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/tyee-ai/gpumon.git
cd gpumon
git pull origin master
```

### 2. Install Dependencies
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure Environment
```bash
# Set RRD data path for your system
export RRD_DATA_PATH="/opt/docker/volumes/docker-observium_config/_data/rrd"
```

### 4. Start Application
```bash
# Development mode
./start_web_host.sh

# Production mode
./start_production.sh

# Or manually
python3 web_app.py
```

## 🌐 Access Points
- **Dashboard**: http://localhost:8090
- **API**: http://localhost:8090/api/analysis
- **Port**: 8090 (configurable in web_app.py)

## 🔍 Troubleshooting

### Analysis Fails
1. Check RRD_DATA_PATH environment variable
2. Verify RRD data directory access
3. Test GPU monitor script: `python3 gpu_monitor.py --site 4 --help`

### Port Issues
1. Check if port 8090 is available
2. Verify firewall settings
3. Check for other processes using the port

## 📊 Monitoring
- Check application logs for errors
- Monitor GPU analysis results
- Verify RRD data access

## 🚀 Production Deployment
For production use, consider:
- Using systemd service (gpu-monitor.service)
- Setting up reverse proxy (nginx)
- Implementing SSL/TLS
- Adding monitoring and alerting
