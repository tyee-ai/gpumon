# Deploying GPU Monitor to Remote Host (10.4.231.200)

## Prerequisites
- Docker and Docker Compose installed on remote host
- Access to RRD files that require sudo permissions
- Network access to port 8090

## Deployment Steps

### 1. Clone the Repository
```bash
git clone https://github.com/tyee-ai/gpumon.git
cd gpumon
```

### 2. Build and Run Production Container
```bash
# Build the production image
docker build -f Dockerfile.prod -t gpumon:prod .

# Run with RRD data access
docker run -d \
  --name gpumon-prod \
  -p 8090:5000 \
  -v /path/to/your/rrd/files:/app/data:ro \
  -v /var/log/gpumon:/app/logs \
  --restart unless-stopped \
  gpumon:prod
```

### 3. Or Use Docker Compose
```bash
# Update the volume path in docker-compose.prod.yml to point to your RRD files
# Then run:
docker-compose -f docker-compose.prod.yml up -d --build
```

### 4. Test RRD Access
```bash
# Test if the container can access RRD files
docker exec -it gpumon-prod python3 test_rrd_access.py

# Check container logs
docker logs gpumon-prod
```

### 5. Verify Web Interface
- Open browser to: http://10.4.231.200:8090
- Try running an analysis to see if RRD access works

## Troubleshooting

### Permission Issues
If you still get permission errors:
```bash
# Check what user owns the RRD files
ls -la /path/to/your/rrd/files

# You might need to adjust file permissions or mount differently
```

### RRD File Path
Make sure the volume mount points to the correct RRD directory:
```bash
# Example for Ganglia RRD files
-v /var/lib/ganglia/rrds:/app/data:ro

# Example for custom RRD location
-v /opt/gpu-monitoring/rrd:/app/data:ro
```

### Network Access
Ensure port 8090 is accessible from your network:
```bash
# Check if port is open
netstat -tlnp | grep 8090

# Or check with ss
ss -tlnp | grep 8090
```

## Security Note
The container now runs as root to access RRD files. In production, consider:
- Using file ACLs to grant specific permissions
- Running with specific user/group mappings
- Limiting container capabilities
