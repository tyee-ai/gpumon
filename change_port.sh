#!/bin/bash

echo "🔧 Changing Docker Compose port from 8090 to 8091..."

# Backup original file
cp docker-compose.yml docker-compose.yml.backup

# Change the port
sed -i 's/8090:5000/8091:5000/' docker-compose.yml

echo "✅ Port changed to 8091"
echo "📁 Backup saved as docker-compose.yml.backup"
echo ""
echo "🚀 Now you can run:"
echo "docker-compose up --build"
echo ""
echo "🌐 Access at: http://localhost:8091"
