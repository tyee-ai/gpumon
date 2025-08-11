# GPU Monitor - Docker Setup

This document describes how to run the GPU Monitor application using Docker.

## Quick Start

### Development Mode
```bash
# Build and run in development mode
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### Production Mode
```bash
# Build and run in production mode with gunicorn
docker-compose -f docker-compose.prod.yml up --build

# Or run in background
docker-compose -f docker-compose.prod.yml up -d --build
```

## Docker Commands

### Build the image
```bash
docker build -t gpumon .
```

### Run the container
```bash
docker run -p 8090:5000 gpumon
```

### Run with custom data directory
```bash
docker run -p 8090:5000 -v /path/to/rrd/data:/app/data:ro gpumon
```

## Environment Variables

- `FLASK_ENV`: Set to `production` for production mode
- `FLASK_DEBUG`: Set to `0` for production mode

## Volumes

- `./data:/app/data:ro`: Mount RRD data directory (read-only)
- `./logs:/app/logs`: Mount logs directory

## Health Check

The container includes a health check that verifies the web application is responding:
- Interval: 30 seconds
- Timeout: 10 seconds
- Retries: 3
- Start period: 40 seconds

## Production Features

- Uses gunicorn with 4 workers
- Non-root user for security
- Health checks enabled
- Automatic restart policy
- Optimized for production workloads

## Troubleshooting

### Check container logs
```bash
docker-compose logs gpumon
```

### Access container shell
```bash
docker exec -it gpumon-app bash
```

### Check container health
```bash
docker inspect gpumon-app | grep Health -A 10
```
