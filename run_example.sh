#!/bin/bash

echo "🚀 GPU RRD Monitor - Usage Examples"
echo "==================================="
echo ""

echo "1️⃣  Basic Analysis (Last Hour):"
echo "   docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14"
echo ""

echo "2️⃣  Full Analysis (Date Range):"
echo "   docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 14 --full --start-date 2024-08-01 --end-date 2024-08-09"
echo ""

echo "3️⃣  Using Docker Compose:"
echo "   docker-compose run --rm gpu-rrd-monitor /rrd-data --site 14"
echo ""

echo "4️⃣  Test with Different Site:"
echo "   docker run --rm -v /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd:/rrd-data:ro gpu-rrd-monitor /rrd-data --site 15"
echo ""

echo "📁 RRD Data Path: /opt/docker/volumes/ce6610072ec75cc34f7d4e362f935736e47de7c0d59344d518393aa288805333/_data/rrd"
echo "🔧 Site Pattern: 10.{SITE}.*.* (e.g., 10.14.*.* for site 14)"
echo "🌡️  Thresholds: Throttled > 80°C, Suspicious ≥8°C above average when average < 30°C"
