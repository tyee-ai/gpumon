# GPU RRD Monitor - Web Frontend

A beautiful web interface for GPU RRD temperature analysis with real-time filtering and visualization.

## 🌟 Features

### 🏢 Site Management
- **DFW2 Site**: Configured for Dallas-Fort Worth Data Center 2
- **IP Subnet**: Automatically uses 10.4.*.* pattern for device discovery
- **Easy Expansion**: Simple to add more sites in the future

### 📅 Date Range Selection
- **Flexible Dates**: Choose custom start and end dates
- **Default Range**: Pre-configured for last 7 days
- **Full Analysis**: Process complete historical data

### 🚨 Alert Type Filtering
- **Throttled GPUs**: Temperature > 80°C
- **Thermally Failed**: ≥8°C hotter than others when average < 30°C
- **Both Types**: View all alerts together
- **Real-time Results**: Instant filtering and display

### 🎨 Modern UI
- **Responsive Design**: Works on desktop and mobile
- **Beautiful Cards**: Clean, professional interface
- **Loading States**: Visual feedback during analysis
- **Error Handling**: User-friendly error messages

## 🚀 Quick Start

### 1. Start the Web Application
```bash
./start_web.sh
```

### 2. Access the Dashboard
Open your browser and go to: **http://localhost:5000**

### 3. Configure Analysis
- **Site**: DFW2 (pre-selected)
- **Start Date**: Choose start date
- **End Date**: Choose end date  
- **Alert Type**: Select filtering option

### 4. Run Analysis
Click **"Run Analysis"** and wait for results

## 🐳 Docker Commands

### Build and Start
```bash
# Build the image
docker-compose build

# Start the web application
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the application
docker-compose down
```

### Manual Docker Run
```bash
docker run -d \
  --name gpu-rrd-monitor-web \
  -p 5000:5000 \
  -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro \
  gpu-rrd-monitor
```

## 📊 Understanding Results

### Summary Cards
- **Total Devices**: Number of devices analyzed
- **Throttled GPUs**: Count of GPUs above 80°C
- **Thermally Failed**: Count of suspicious temperature differentials

### Alert Details
- **Throttled Alerts**: GPU ID, Device, Temperature, Timestamp
- **Thermally Failed**: GPU ID, Device, Temperature, Average, Timestamp
- **Raw Output**: Complete analysis output for debugging

### Filtering Logic
- **Throttled**: `temp > 80°C`
- **Thermally Failed**: `avg_temp < 30°C AND temp > avg_temp + 8°C`

## 🔧 Configuration

### Adding New Sites
Edit `web_app.py` and add to the `SITES` dictionary:
```python
SITES = {
    "DFW2": {
        "name": "DFW2",
        "subnet": "10.4",
        "description": "Dallas-Fort Worth Data Center 2"
    },
    "NEW_SITE": {
        "name": "NEW_SITE", 
        "subnet": "10.5",
        "description": "New Site Description"
    }
}
```

### Modifying Thresholds
Edit `gpu_monitor.py`:
```python
# Temperature thresholds
THROTTLED_THRESHOLD = 85  # °C
SUSPICIOUS_DELTA = 10     # °C
COLD_THRESHOLD = 30       # °C
```

## 📁 Project Structure

```
gpu-rrd-monitor/
├── web_app.py              # Flask web application
├── gpu_monitor.py          # GPU analysis engine
├── templates/
│   └── index.html         # Main dashboard template
├── static/
│   └── js/
│       └── dashboard.js   # Frontend JavaScript
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Docker Compose configuration
├── requirements.txt        # Python dependencies
├── start_web.sh           # Web app startup script
└── README_WEB.md          # This file
```

## 🌐 API Endpoints

### GET /
- **Description**: Main dashboard page
- **Response**: HTML dashboard interface

### GET /api/analysis
- **Parameters**: 
  - `site`: Site identifier (e.g., "DFW2")
  - `start_date`: Start date (YYYY-MM-DD)
  - `end_date`: End date (YYYY-MM-DD)
  - `alert_type`: Filter type ("throttled", "thermally_failed", "both")
- **Response**: JSON with analysis results

### GET /api/sites
- **Description**: Get available sites
- **Response**: JSON with site configurations

## 🚨 Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Check what's using port 5000
sudo lsof -i :5000

# Kill the process or change port in docker-compose.yml
```

**Permission Denied**
```bash
# Ensure Docker has access to RRD directory
sudo chmod 755 /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd
```

**Analysis Timeout**
- Increase timeout in `web_app.py` (default: 300 seconds)
- Check RRD file sizes and data volume

### Debug Mode
```bash
# Run with debug output
docker-compose logs -f gpu-rrd-monitor

# Check container status
docker-compose ps
```

## 🔮 Future Enhancements

- **Multi-site Support**: Add more data centers
- **Real-time Monitoring**: Live temperature updates
- **Alert Notifications**: Email/Slack integration
- **Historical Trends**: Temperature graphs over time
- **Export Options**: PDF reports, CSV downloads
- **User Authentication**: Secure access control

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review Docker logs: `docker-compose logs -f`
3. Verify RRD file accessibility
4. Check network connectivity to RRD data directory

---

**🎉 Enjoy your GPU monitoring dashboard!**
