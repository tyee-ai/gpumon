#!/bin/bash

# Production Deployment Script for GPU Monitor
# Usage: ./scripts/deploy_production.sh [environment]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
COMPOSE_FILE="docker-compose.prod.yml"
APP_NAME="gpumon"
BACKUP_DIR="/opt/gpumon/backups"
LOG_DIR="/opt/gpumon/logs"
DATA_DIR="/opt/gpumon/rrd_data"
SSL_DIR="/opt/gpumon/ssl"

echo -e "${GREEN}🚀 Starting production deployment for ${APP_NAME}...${NC}"

# Docker CE installation functions
install_docker_ce() {
    echo -e "${YELLOW}📦 Installing Docker CE...${NC}"
    
    # Remove any existing Docker installations (including snap)
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
    sudo snap remove docker || true
    
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
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt-get update
    
    # Install Docker CE
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    echo -e "${GREEN}✅ Docker CE installed successfully!${NC}"
    echo -e "${YELLOW}⚠️  Please logout and login again for group changes to take effect, then run this script again.${NC}"
    exit 0
}

install_docker_compose() {
    echo -e "${YELLOW}📦 Installing Docker Compose...${NC}"
    
    # Remove any existing docker-compose
    sudo rm -f /usr/local/bin/docker-compose
    
    # Download latest Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Make it executable
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Verify installation
    docker-compose --version
    
    echo -e "${GREEN}✅ Docker Compose installed successfully!${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ This script should not be run as root${NC}"
   exit 1
fi

# Check for and remove snap Docker if it exists
check_and_remove_snap_docker() {
    if snap list | grep -q docker; then
        echo -e "${YELLOW}⚠️  Snap Docker detected. Removing it...${NC}"
        sudo snap remove docker
        echo -e "${GREEN}✅ Snap Docker removed successfully!${NC}"
    fi
}

# Check Docker installation
check_and_remove_snap_docker

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Docker not found. Installing Docker CE...${NC}"
    install_docker_ce
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}🐳 Docker Compose not found. Installing...${NC}"
    install_docker_compose
fi

# Create necessary directories
echo -e "${YELLOW}📁 Creating production directories...${NC}"
sudo mkdir -p $BACKUP_DIR $LOG_DIR $DATA_DIR $SSL_DIR
sudo chown -R $USER:$USER $BACKUP_DIR $LOG_DIR $DATA_DIR $SSL_DIR

# Backup existing deployment if it exists
if docker ps -q -f name=${APP_NAME} | grep -q .; then
    echo -e "${YELLOW}💾 Creating backup of existing deployment...${NC}"
    docker-compose -f $COMPOSE_FILE down || true
    sudo cp -r $DATA_DIR $BACKUP_DIR/$(date +%Y%m%d_%H%M%S)_rrd_data || true
fi

# Generate SSL certificates (self-signed for testing)
echo -e "${YELLOW}🔐 Generating SSL certificates...${NC}"
if [ ! -f "$SSL_DIR/cert.pem" ] || [ ! -f "$SSL_DIR/key.pem" ]; then
    sudo openssl req -x509 -newkey rsa:4096 -keyout $SSL_DIR/key.pem -out $SSL_DIR/cert.pem -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=10.15.231.200"
    sudo chown $USER:$USER $SSL_DIR/*
fi

# Set proper permissions
echo -e "${YELLOW}🔒 Setting proper permissions...${NC}"
chmod 600 $SSL_DIR/key.pem
chmod 644 $SSL_DIR/cert.pem

# Build and start services
echo -e "${YELLOW}🏗️  Building production images...${NC}"
docker-compose -f $COMPOSE_FILE build --no-cache

echo -e "${YELLOW}🚀 Starting production services...${NC}"
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be healthy...${NC}"
sleep 30

# Check service health
if docker-compose -f $COMPOSE_FILE ps | grep -q "healthy"; then
    echo -e "${GREEN}✅ Services are healthy!${NC}"
else
    echo -e "${RED}❌ Services are not healthy. Check logs:${NC}"
    docker-compose -f $COMPOSE_FILE logs
    exit 1
fi

# Create systemd service for auto-start
echo -e "${YELLOW}🔧 Creating systemd service...${NC}"
sudo tee /etc/systemd/system/gpumon.service > /dev/null <<EOF
[Unit]
Description=GPU Monitor Production Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose -f $COMPOSE_FILE up -d
ExecStop=/usr/local/bin/docker-compose -f $COMPOSE_FILE down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start systemd service
sudo systemctl daemon-reload
sudo systemctl enable gpumon.service

# Create log rotation
echo -e "${YELLOW}📋 Setting up log rotation...${NC}"
sudo tee /etc/logrotate.d/gpumon > /dev/null <<EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        docker-compose -f $COMPOSE_FILE restart gpumon
    endscript
}
EOF

# Create monitoring script
echo -e "${YELLOW}📊 Creating monitoring script...${NC}"
tee scripts/monitor_production.sh > /dev/null <<EOF
#!/bin/bash
# Production monitoring script

echo "=== GPU Monitor Production Status ==="
echo "Time: \$(date)"
echo ""

echo "=== Docker Services ==="
docker-compose -f $COMPOSE_FILE ps

echo ""
echo "=== Service Logs (last 10 lines) ==="
docker-compose -f $COMPOSE_FILE logs --tail=10

echo ""
echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo ""
echo "=== Disk Usage ==="
df -h $DATA_DIR $LOG_DIR
EOF

chmod +x scripts/monitor_production.sh

# Create backup script
echo -e "${YELLOW}💾 Creating backup script...${NC}"
tee scripts/backup_production.sh > /dev/null <<EOF
#!/bin/bash
# Production backup script

BACKUP_NAME="gpumon_\$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/\$BACKUP_NAME"

echo "Creating backup: \$BACKUP_NAME"

# Stop services
docker-compose -f $COMPOSE_FILE down

# Create backup
sudo cp -r $DATA_DIR \$BACKUP_PATH

# Restart services
docker-compose -f $COMPOSE_FILE up -d

echo "Backup created: \$BACKUP_PATH"
echo "Backup size: \$(du -sh \$BACKUP_PATH | cut -f1)"
EOF

chmod +x scripts/backup_production.sh

# Final status
echo -e "${GREEN}🎉 Production deployment completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Deployment Summary:${NC}"
echo "  • Application: $APP_NAME"
echo "  • Environment: $ENVIRONMENT"
echo "  • Compose file: $COMPOSE_FILE"
echo "  • Data directory: $DATA_DIR"
echo "  • Log directory: $LOG_DIR"
echo "  • SSL directory: $SSL_DIR"
echo "  • Backup directory: $BACKUP_DIR"
echo ""
echo -e "${YELLOW}🔗 Access URLs:${NC}"
echo "  • HTTP: http://10.15.231.200:8090 (redirects to HTTPS)"
echo "  • HTTPS: https://10.15.231.200:8443"
echo ""
echo -e "${YELLOW}📚 Useful Commands:${NC}"
echo "  • View logs: docker-compose -f $COMPOSE_FILE logs -f"
echo "  • Monitor: ./scripts/monitor_production.sh"
echo "  • Backup: ./scripts/backup_production.sh"
echo "  • Restart: sudo systemctl restart gpumon"
echo "  • Status: sudo systemctl status gpumon"
echo ""
echo -e "${GREEN}✅ Your GPU Monitor is now running in production!${NC}"
