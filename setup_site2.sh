#!/bin/bash

# Setup script for SITE2 (10.5.x.x subnet)
# This creates the directory structure and sample RRD files for testing

echo "🏗️  Setting up SITE2 infrastructure..."

# Create the main directory structure
sudo mkdir -p /opt/docker/volumes/site2_observium_config/_data/rrd

# Create device directories for SITE2
# Cluster 1: 10.5.11.1 to 10.5.11.10 (10 devices)
# Cluster 2: 10.5.21.1 to 10.5.21.10 (10 devices)

echo "📁 Creating device directories for SITE2..."

# Cluster 1 devices (10.5.11.x)
for i in {1..10}; do
    sudo mkdir -p /opt/docker/volumes/site2_observium_config/_data/rrd/10.5.11.$i
    echo "  Created: 10.5.11.$i"
done

# Cluster 2 devices (10.5.21.x)  
for i in {1..10}; do
    sudo mkdir -p /opt/docker/volumes/site2_observium_config/_data/rrd/10.5.21.$i
    echo "  Created: 10.5.21.$i"
done

echo "📊 Creating sample RRD files..."

# GPU OIDs to create RRD files for
GPU_OIDS=("1.4" "1.5" "1.6" "1.7" "1.8" "1.9" "1.10" "1.11")

# Function to create a sample RRD file
create_sample_rrd() {
    local device_dir=$1
    local oid=$2
    
    # Create a simple RRD file with some sample data
    # This is a minimal RRD file for testing purposes
    rrdtool create "$device_dir/sensor-temperature-IDRAC-MIB-SMIv2-temperatureProbeReading-${oid}.rrd" \
        --start 1609459200 \
        --step 300 \
        DS:temperature:GAUGE:600:0:100 \
        RRA:AVERAGE:0.5:1:288 \
        RRA:AVERAGE:0.5:12:168 \
        RRA:AVERAGE:0.5:288:365
}

# Create RRD files for all devices
for device_dir in /opt/docker/volumes/site2_observium_config/_data/rrd/10.5.*; do
    if [ -d "$device_dir" ]; then
        device_ip=$(basename "$device_dir")
        echo "  Creating RRD files for $device_ip..."
        
        for oid in "${GPU_OIDS[@]}"; do
            create_sample_rrd "$device_dir" "$oid"
        done
    fi
done

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R root:root /opt/docker/volumes/site2_observium_config/
sudo chmod -R 755 /opt/docker/volumes/site2_observium_config/

echo "✅ SITE2 setup complete!"
echo ""
echo "📋 Summary:"
echo "  - Created 20 device directories (10.5.11.1-10, 10.5.21.1-10)"
echo "  - Created 8 RRD files per device (GPU_21 through GPU_28)"
echo "  - Total: 160 RRD files created"
echo ""
echo "🧪 Test the setup:"
echo "  python3 gpu_monitor.py --site SITE2"
echo "  python3 gpu_monitor.py --site 5"


