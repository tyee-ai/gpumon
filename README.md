# GPU RRD Monitor

A Docker-based application that queries RRD files directly for GPU temperature analysis without creating CSV files.

## Features

- **Direct RRD Querying**: Queries RRD files directly using rrdtool
- **Two Threshold Filters**:
  - **Throttled GPUs**: GPUs with temperature > 80°C
  - **Thermally Failed**: GPUs ≥8°C hotter than others when those others are <30°C
- **Screen Output**: Results displayed directly to console (no CSV generation)
- **Docker Containerized**: Easy deployment and isolation

## Quick Start

### Build the Docker Image
```bash
docker build -t gpu-rrd-monitor .
```

### Run Basic Analysis (Last Hour)
```bash
docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14
```

### Run Full Analysis (Date Range)
```bash
docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14 --full --start-date 2024-08-01 --end-date 2024-08-09
```

## Using Docker Compose

### Build and Run
```bash
# Build the image
docker-compose build

# Run basic analysis
docker-compose run --rm gpu-rrd-monitor /rrd-data --site 14

# Run full analysis
docker-compose run --rm gpu-rrd-monitor /rrd-data --site 14 --full --start-date 2024-08-01 --end-date 2024-08-09
```

## Configuration

### Environment Variables
- `SITE`: Site ID for device pattern matching (default: 14)
- `BASE_PATH`: Base path to RRD data directory

### GPU Mapping
The script maps specific OIDs to GPU identifiers:
- 1.4 → GPU_21
- 1.5 → GPU_22
- 1.6 → GPU_23
- 1.7 → GPU_24
- 1.8 → GPU_25
- 1.9 → GPU_26
- 1.10 → GPU_27
- 1.11 → GPU_28

### Thresholds
- **Throttled**: > 80°C
- **Suspicious Delta**: ≥8°C above average when average < 30°C

## Output Format

### Basic Analysis (Last Hour)
```
[Thermally Failed] 2024-08-09T22:30:00 device-10.14.1.1 GPU_21 Temp: 45.2C Avg: 32.1C (seen 3x)
🔥 2024-08-09T22:30:00 device-10.14.1.1 GPU_21 Temp: 85.5°C
```

### Full Analysis
```
🚨 FULL ANALYSIS RESULTS
============================================================

🔥 THROTTLED GPUs (5):
  • 2024-08-09T22:30:00 device-10.14.1.1 GPU_21 Temp: 85.5°C

⚠️  THERMALLY FAILED GPUs (12):
  • 2024-08-09T22:30:00 device-10.14.1.1 GPU_21 Temp: 45.2°C (Avg: 32.1°C)
```

## File Structure

```
gpu-rrd-monitor/
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Docker Compose configuration
├── gpu_monitor.py          # Main Python script
├── requirements.txt        # Python dependencies
└── README.md              # This file
```

## Troubleshooting

### Permission Issues
Ensure the Docker container has read access to the RRD directory:
```bash
docker run --rm -v /path/to/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data
```

### RRD File Not Found
Verify the RRD files exist and the path is correct:
```bash
ls -la /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd
```

### Site Pattern Mismatch
Check if devices match the expected pattern (e.g., `10.14.*.*`):
```bash
docker run --rm -v /path/to/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14
```
