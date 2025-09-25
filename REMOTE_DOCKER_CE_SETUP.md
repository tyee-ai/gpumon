# 🐳 Docker CE Remote Deployment Guide
## Target: 10.15.231.200

### **Prerequisites**

1. **SSH Access** to 10.15.231.200
2. **Root or sudo access** on the remote node
3. **Network access** to port 8090

### **Step 1: Install Docker CE on Remote Node**

```bash
# SSH to the remote node
ssh user@10.15.231.200

# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker CE
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional)
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify installation
docker --version
docker compose version
```

### **Step 2: Deploy GPU Monitor**

```bash
# Clone the repository
git clone https://github.com/tyee-ai/gpumon.git
cd gpumon

# Switch to multisite branch
git checkout multisite

# Make deployment script executable
chmod +x deploy-remote-docker-ce.sh

# Run the deployment script
./deploy-remote-docker-ce.sh
```

### **Step 3: Configure RRD Data Path**

The deployment script will check for RRD data at:
- `/opt/docker/volumes/docker-observium_config/_data/rrd`

If your RRD data is in a different location, update the path in `docker-compose.remote.yml`:

```yaml
volumes:
  - /your/actual/rrd/path:/app/data:ro
```

### **Step 4: Access the Application**

Once deployed, the GPU Monitor will be available at:
- **Local**: http://localhost:8090
- **Remote**: http://10.15.231.200:8090
- **Health Check**: http://10.15.231.200:8090/api/health

### **Step 5: Verify Deployment**

```bash
# Check container status
docker ps

# View logs
docker logs gpumon-remote -f

# Test API endpoints
curl http://10.15.231.200:8090/api/health
curl http://10.15.231.200:8090/api/sites
```

### **Management Commands**

```bash
# Stop the application
docker compose -f docker-compose.remote.yml down

# Start the application
docker compose -f docker-compose.remote.yml up -d

# Restart the application
docker compose -f docker-compose.remote.yml restart

# Update the application
git pull
docker compose -f docker-compose.remote.yml up -d --build

# View logs
docker logs gpumon-remote -f

# Access container shell
docker exec -it gpumon-remote /bin/bash
```

### **Current Configuration**

The deployment includes:
- **DFW1**: Allen Texas (254 nodes, 2,032 GPUs)
  - Subnets: 10.19.21.0/24, 10.19.31.0/24
- **DFW2**: Dallas-Fort Worth 2 (254 nodes, 2,032 GPUs)
  - Subnet: 10.4.0.0/16

### **Troubleshooting**

#### **Container Won't Start**
```bash
# Check logs
docker logs gpumon-remote

# Check if port is in use
sudo netstat -tlnp | grep 8090

# Check Docker daemon
sudo systemctl status docker
```

#### **RRD Data Not Found**
```bash
# Find RRD data on your system
find / -name "*.rrd" -type f 2>/dev/null | head -10

# Update docker-compose.remote.yml with correct path
nano docker-compose.remote.yml
```

#### **Permission Issues**
```bash
# Check file permissions
ls -la /opt/docker/volumes/docker-observium_config/_data/rrd

# Fix permissions if needed
sudo chmod -R 755 /opt/docker/volumes/docker-observium_config/_data/rrd
```

#### **Network Issues**
```bash
# Check if port is accessible
telnet 10.15.231.200 8090

# Check firewall
sudo ufw status
sudo ufw allow 8090
```

### **Security Considerations**

1. **Firewall**: Ensure port 8090 is properly configured
2. **SSL**: Consider setting up HTTPS for production
3. **Authentication**: The current setup has no authentication
4. **Updates**: Regularly update the application and dependencies

### **Monitoring**

```bash
# Check container health
docker inspect gpumon-remote | grep -A 10 Health

# Monitor resource usage
docker stats gpumon-remote

# Check disk usage
docker system df
```

### **Backup**

```bash
# Backup configuration
tar -czf gpumon-backup-$(date +%Y%m%d).tar.gz site_config.py docker-compose.remote.yml

# Backup logs
docker logs gpumon-remote > gpumon-logs-$(date +%Y%m%d).log
```
