# GPU Monitor Application

A comprehensive web-based monitoring system for GPU thermal analysis using RRD (Round Robin Database) data.

## 🚀 Features

- **Real-time Dashboard**: Live cluster status monitoring with automatic updates
- **Historical Analysis**: Query GPU throttling and thermal failure data by date range
- **Analytics Dashboard**: GPU breakdown with custom color-coded status indicators
- **Multi-site Support**: Monitor multiple data center locations
- **Docker Deployment**: Containerized application for easy deployment
- **RESTful API**: JSON API for integration with other systems

## 📊 Dashboard Features

### Home Dashboard (`/`)
- Real-time cluster status boxes (C1, C2)
- Automatic polling every 15 minutes
- Color-coded status indicators (Green = Healthy, Red = Throttling)
- Live clock and last poll timestamp
- Detailed alert information for throttled GPUs

### Query Tool (`/query`)
- Historical data analysis by date range
- Filter by alert type (Throttled, Thermally Failed, Both)
- Aggregated results with first/last alert dates
- Day count calculations for multi-day alerts

### Analytics Dashboard (`/analytics`)
- GPU-specific breakdown (GPU_24 through GPU_25)
- Custom color scale based on throttling percentage
- Date range filtering
- Summary statistics

## 🏗️ Architecture

```
gpumon/
├── app/                    # Application modules
│   ├── api/               # API handlers
│   ├── config/            # Configuration management
│   └── utils/             # Utility functions
├── config/                # Configuration files
├── docs/                  # Documentation
├── scripts/               # Deployment and utility scripts
│   ├── deploy/           # Deployment scripts
│   └── test/             # Testing scripts
├── static/               # Static assets
│   └── js/              # JavaScript files
├── templates/            # HTML templates
├── gpu_monitor.py        # Core GPU analysis engine
├── web_app.py           # Flask web application
└── Dockerfile           # Docker container definition
```

## 🛠️ Installation

### Prerequisites

- Python 3.8+
- Docker (for containerized deployment)
- RRD data files
- rrdtool command-line tool

### Quick Start

1. **Clone the repository:**
```bash
git clone <repository-url>
cd gpumon
```

2. **Deploy with Docker:**
```bash
# Make deployment script executable
chmod +x scripts/deploy/deploy.sh

# Deploy with default settings
./scripts/deploy/deploy.sh deploy

# Deploy with custom port
./scripts/deploy/deploy.sh deploy 8091

# Deploy with custom RRD path
./scripts/deploy/deploy.sh deploy 8090 /custom/rrd/path
```

3. **Access the application:**
- Home Dashboard: http://localhost:8090/
- Query Tool: http://localhost:8090/query
- Analytics: http://localhost:8090/analytics

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_HOST` | `0.0.0.0` | Flask host address |
| `FLASK_PORT` | `8090` | Flask port number |
| `FLASK_DEBUG` | `False` | Enable debug mode |
| `RRD_BASE_PATH` | `/app/rrd_data` | Path to RRD data files |
| `API_TIMEOUT` | `300` | API request timeout (seconds) |
| `LOG_LEVEL` | `INFO` | Logging level |

### Site Configuration

Sites are configured in `config/settings.py`:

```python
SITES = {
    'DFW2': {
        'name': 'DFW2',
        'subnet': '10.4.*.*',
        'description': 'Dallas Fort Worth Data Center 2'
    }
}
```

## 🚀 Deployment

### Docker Deployment (Recommended)

```bash
# Build and deploy
docker build -t gpumon:latest .
docker run -d \
  --name gpumon-container \
  -p 8090:8090 \
  -v /path/to/rrd/data:/app/rrd_data \
  -e RRD_BASE_PATH=/app/rrd_data \
  -e FLASK_PORT=8090 \
  gpumon:latest
```

### Manual Deployment

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Set environment variables:**
```bash
export RRD_BASE_PATH=/path/to/rrd/data
export FLASK_PORT=8090
```

3. **Run the application:**
```bash
python3 web_app.py
```

## 📡 API Reference

### Endpoints

#### `GET /api/analysis`
Query GPU analysis data.

**Parameters:**
- `site` (string): Site identifier (e.g., "DFW2")
- `start_date` (string): Start date (YYYY-MM-DD)
- `end_date` (string): End date (YYYY-MM-DD)
- `alert_type` (string): Alert type ("throttled", "thermally_failed", "both")

**Example:**
```bash
curl "http://localhost:8090/api/analysis?site=DFW2&start_date=2025-08-13&end_date=2025-08-14&alert_type=throttled"
```

#### `GET /api/sites`
Get available sites.

**Example:**
```bash
curl "http://localhost:8090/api/sites"
```

### Response Format

```json
{
  "success": true,
  "results": {
    "throttled": [
      {
        "device": "10.4.11.36",
        "gpu_id": "GPU_25",
        "temp": 89.7,
        "timestamp": "2025-08-13 00:00:00",
        "site": "DFW2",
        "cluster": "C1"
      }
    ],
    "thermally_failed": [],
    "summary": {
      "total_devices": 516,
      "throttled_count": 1,
      "suspicious_count": 0
    }
  }
}
```

## 🔍 Troubleshooting

### Common Issues

1. **API returns 500 errors:**
   - Check if RRD data path is correct
   - Verify rrdtool is installed in container
   - Check container logs: `docker logs gpumon-container`

2. **No data returned:**
   - Verify RRD files exist and are accessible
   - Check date range is valid
   - Ensure site configuration is correct

3. **Container won't start:**
   - Check if port 8090 is available
   - Verify Docker is running
   - Check Docker logs for errors

### Debug Commands

```bash
# Check container status
docker ps -a

# View container logs
docker logs gpumon-container

# Test RRD access
docker exec -it gpumon-container ls -la /app/rrd_data

# Test API directly
curl "http://localhost:8090/api/analysis?site=DFW2&start_date=2025-08-13&end_date=2025-08-14&alert_type=throttled"
```

## 🧪 Testing

### Run Tests

```bash
# Run deployment script tests
./scripts/deploy/deploy.sh health

# Test API endpoints
curl "http://localhost:8090/api/sites"
curl "http://localhost:8090/api/analysis?site=DFW2&start_date=2025-08-13&end_date=2025-08-14&alert_type=both"
```

## 📝 Development

### Project Structure

- **`web_app.py`**: Main Flask application
- **`gpu_monitor.py`**: GPU analysis engine
- **`templates/`**: HTML templates
- **`static/js/`**: JavaScript files
- **`config/`**: Configuration files
- **`scripts/`**: Deployment and utility scripts

### Adding New Features

1. **Backend changes**: Modify `web_app.py` or `gpu_monitor.py`
2. **Frontend changes**: Update templates in `templates/`
3. **Configuration**: Update `config/settings.py`
4. **Deployment**: Update `scripts/deploy/deploy.sh`

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For support and questions:
- Check the troubleshooting section
- Review the API documentation
- Check container logs for errors
- Open an issue on the repository
