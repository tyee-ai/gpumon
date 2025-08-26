# 🚀 Production Deployment Guide for GPU Monitor

This guide will help you deploy your multi-site GPU monitoring application to a production remote machine with proper security, monitoring, and maintenance.

## 📋 Prerequisites

### **Remote Machine Requirements:**
- Ubuntu 20.04+ or similar Linux distribution
- Minimum 4GB RAM, 2 CPU cores
- 50GB+ available disk space
- Network access to your GPU data sources
- Non-root user with sudo privileges

### **Network Requirements:**
- Port 8090 (HTTP - redirects to HTTPS on 8443)
- Port 8443 (HTTPS - main application)
- Port 8090 (internal Docker communication)

## 🎯 Quick Start (Automated)

### **1. Transfer Your Code:**
```bash
# On your local machine
git clone https://github.com/yourusername/gpumon.git
cd gpumon
git checkout multisite-docker

# Transfer to remote machine
scp -r . user@remote-server:/home/user/gpumon/
```

### **2. Run Automated Deployment:**
```bash
# SSH to remote machine
ssh user@remote-server

# Navigate to project directory
cd gpumon

# Run deployment script
./scripts/deploy_production.sh
```

### **3. Access Your Application:**
- **HTTPS:** `https://your-server-ip:8443`
- **HTTP:** `http://your-server-ip:8090` (redirects to HTTPS on 8443)

## 🔧 Manual Installation (Step-by-Step)

### **Step 1: Install Docker CE (No Snap!)**

```bash
# Remove any existing Docker installations
sudo apt-get remove -y docker docker-engine docker.io containerd runc
sudo snap remove docker  # Remove snap Docker if it exists

# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update

# Install Docker CE
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Logout and login again for group changes to take effect
exit
# SSH back in
ssh user@remote-server
```

### **Step 2: Install Docker Compose**

```bash
# Download latest Docker Compose
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### **Step 3: Create Production Directories**

```bash
# Create necessary directories
sudo mkdir -p /opt/gpumon/{rrd_data,logs,ssl,backups}
sudo chown -R $USER:$USER /opt/gpumon
```

### **Step 4: Generate SSL Certificates**

```bash
# Generate self-signed certificates (for testing)
sudo openssl req -x509 -newkey rsa:4096 \
    -keyout /opt/gpumon/ssl/key.pem \
    -out /opt/gpumon/ssl/cert.pem \
    -days 365 -nodes \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=10.15.231.200"

# Set proper permissions
sudo chown $USER:$USER /opt/gpumon/ssl/*
chmod 600 /opt/gpumon/ssl/key.pem
chmod 644 /opt/gpumon/ssl/cert.pem
```

### **Step 5: Deploy Application**

```bash
# Navigate to project directory
cd /home/user/gpumon

# Build and start services
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Check service health
docker-compose -f docker-compose.prod.yml ps
```

## 🔒 Security Configuration

### **Firewall Setup:**
```bash
# Install UFW if not present
sudo apt-get install ufw

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 8090/tcp
sudo ufw allow 8443/tcp
sudo ufw enable

# Check status
sudo ufw status
```

### **SSL/TLS Configuration:**
For production, use Let's Encrypt certificates instead of self-signed:

```bash
# Install Certbot
sudo apt-get install certbot

# Get certificates (replace with your domain)
sudo certbot certonly --standalone -d 10.15.231.200

# Copy certificates to application directory
sudo cp /etc/letsencrypt/live/10.15.231.200/fullchain.pem /opt/gpumon/ssl/cert.pem
sudo cp /etc/letsencrypt/live/10.15.231.200/privkey.pem /opt/gpumon/ssl/key.pem
sudo chown $USER:$USER /opt/gpumon/ssl/*
```

## 📊 Monitoring and Maintenance

### **Health Checks:**
```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Check resource usage
docker stats
```

### **Backup and Recovery:**
```bash
# Create backup
./scripts/backup_production.sh

# Restore from backup (manual process)
sudo cp -r /opt/gpumon/backups/backup_name/rrd_data /opt/gpumon/
sudo chown -R $USER:$USER /opt/gpumon/rrd_data
docker-compose -f docker-compose.prod.yml restart
```

### **Log Rotation:**
Logs are automatically rotated with the following configuration:
- Daily rotation
- 30 days retention
- Compression enabled
- Maximum 10MB per log file

## 🚨 Troubleshooting

### **Common Issues:**

#### **1. Permission Denied Errors:**
```bash
# Fix directory permissions
sudo chown -R $USER:$USER /opt/gpumon
sudo chmod -R 755 /opt/gpumon
```

#### **2. Port Already in Use:**
```bash
# Check what's using the port
sudo netstat -tlnp | grep :443

# Kill the process or change ports in docker-compose.prod.yml
```

#### **3. SSL Certificate Issues:**
```bash
# Regenerate self-signed certificates
sudo rm /opt/gpumon/ssl/*
# Follow SSL generation steps above
```

#### **4. Docker Service Issues:**
```bash
# Restart Docker service
sudo systemctl restart docker

# Check Docker status
sudo systemctl status docker
```

### **Debug Mode:**
```bash
# Run with debug logging
docker-compose -f docker-compose.prod.yml logs -f --tail=100

# Check container health
docker-compose -f docker-compose.prod.yml exec gpumon curl -f http://localhost:8090/api/health
```

## 🔄 Updates and Maintenance

### **Application Updates:**
```bash
# Pull latest code
git pull origin multisite-docker

# Rebuild and restart
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

### **System Updates:**
```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Restart Docker service if needed
sudo systemctl restart docker
```

### **Certificate Renewal (Let's Encrypt):**
```bash
# Renew certificates
sudo certbot renew

# Copy renewed certificates
sudo cp /etc/letsencrypt/live/10.15.231.200/fullchain.pem /opt/gpumon/ssl/cert.pem
sudo cp /etc/letsencrypt/live/10.15.231.200/privkey.pem /opt/gpumon/ssl/key.pem
sudo chown $USER:$USER /opt/gpumon/ssl/*

# Restart services
docker-compose -f docker-compose.prod.yml restart nginx
```

## 📈 Performance Optimization

### **Resource Limits:**
The production configuration includes:
- Memory limit: 1GB per container
- CPU limit: 0.5 cores per container
- Log rotation: 10MB max per log file

### **Scaling Considerations:**
- **Small deployment:** 1-2 GPU clusters, current config is sufficient
- **Medium deployment:** 5-10 GPU clusters, consider increasing memory limits
- **Large deployment:** 10+ GPU clusters, consider load balancing and multiple instances

## 🆘 Support and Resources

### **Useful Commands:**
```bash
# Service management
sudo systemctl start gpumon
sudo systemctl stop gpumon
sudo systemctl restart gpumon
sudo systemctl status gpumon

# Monitoring
./scripts/monitor_production.sh
./scripts/backup_production.sh

# Logs
docker-compose -f docker-compose.prod.yml logs -f
tail -f /opt/gpumon/logs/gpumon.log
```

### **File Locations:**
- **Application:** `/home/user/gpumon/`
- **Data:** `/opt/gpumon/rrd_data/`
- **Logs:** `/opt/gpumon/logs/`
- **SSL:** `/opt/gpumon/ssl/`
- **Backups:** `/opt/gpumon/backups/`

### **Configuration Files:**
- **Docker Compose:** `docker-compose.prod.yml`
- **Nginx:** `nginx/nginx.conf`
- **Environment:** `.env.prod`

---

## 🎉 Congratulations!

Your GPU Monitor is now running in production with:
- ✅ **Multi-site support** (DFW1, DFW2, IAD1, SEA1)
- ✅ **HTTPS encryption** with proper SSL/TLS
- ✅ **Production hardening** (non-root user, resource limits)
- ✅ **Automatic startup** via systemd
- ✅ **Log rotation** and monitoring
- ✅ **Backup and recovery** capabilities
- ✅ **Firewall protection** and security headers

For additional support or customization, refer to the application documentation or create an issue in the project repository.
