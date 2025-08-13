# GPU Monitor Docker Deployment Guide

## 🐳 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Access to RRD data directory (`/opt/docker/volumes/docker-observium_config/_data/rrd`)

### Start the Application
```bash
./start_docker.sh
```

The application will be available at: **http://localhost:8090**

## 🔧 Manual Docker Commands

### Build and Start
```bash
docker-compose up --build -d
```

### Stop
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f gpumon
```

### Check Status
```bash
docker-compose ps
```

## 📁 Volume Mounts

The Docker container mounts:
- **RRD Data**: `/opt/docker/volumes/docker-observium_config/_data/rrd:/app/data:ro`
- **Logs**: `./logs:/app/logs`

## 🌐 Port Configuration

- **Host Port**: 8090
- **Container Port**: 8090
- **Access URL**: http://localhost:8090

## 🔍 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_HOST` | `0.0.0.0` | Flask bind address |
| `FLASK_PORT` | `8090` | Flask port |
| `FLASK_DEBUG` | `False` | Enable debug mode |
| `RRD_DATA_PATH` | `/app/data` | RRD data directory path |

## 🚀 Features

- **Accurate Duration Calculation**: Multi-day GPU throttling events properly calculated
- **Color-Coded Results**: Green for 1-day, red for multi-day events
- **Real-time Analysis**: Direct access to RRD data
- **Site-based Filtering**: DFW2 with 10.4.*.* subnet support
- **Alert Type Filtering**: Throttled, Thermally Failed, or Both

## 🐛 Troubleshooting

### Container Won't Start
```bash
# Check logs
docker-compose logs gpumon

# Check container status
docker-compose ps

# Verify RRD data access
docker exec -it gpumon-app ls /app/data
```

### Permission Issues
If the container can't access RRD data:
```bash
# Check host permissions
ls -la /opt/docker/volumes/docker-observium_config/_data/rrd

# Run with privileged mode (if needed)
docker-compose -f docker-compose.prod.privileged.yml up --build -d
```

### Port Conflicts
If port 8090 is already in use:
```bash
# Check what's using the port
sudo netstat -tlnp | grep :8090

# Stop conflicting service or change port in docker-compose.yml
```

## 🔄 Development Workflow

1. **Make changes** to the code
2. **Rebuild container**: `docker-compose up --build -d`
3. **Test changes** at http://localhost:8090
4. **Commit changes** to git

## 📊 Monitoring

### Health Checks
The container includes health checks that verify the web interface is responding.

### Logs
Application logs are available in the `./logs` directory and via Docker logs.

## 🆘 Support

For issues or questions:
1. Check the logs: `docker-compose logs -f gpumon`
2. Verify RRD data access
3. Check container resource usage: `docker stats gpumon-app`
