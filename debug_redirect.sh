#!/bin/bash

echo "🔍 HTTP to HTTPS Redirect Diagnostic Script"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the gpumon directory."
    exit 1
fi

echo "📋 Step 1: Container Status"
echo "---------------------------"
docker-compose ps
echo ""

echo "📋 Step 2: Environment Variables"
echo "--------------------------------"
echo "Checking if HTTP_PORT and FLASK_PORT are set correctly:"
docker-compose exec gpumon-app env | grep -E "(HTTP_PORT|FLASK_PORT|FLASK_SSL)" || echo "❌ Container not running or exec failed"
echo ""

echo "📋 Step 3: Port Listening Status"
echo "--------------------------------"
echo "Checking if ports 8090 and 8443 are listening:"
netstat -tlnp | grep -E "(8090|8443)" || echo "❌ No ports found listening"
echo ""

echo "📋 Step 4: Container Logs Analysis"
echo "----------------------------------"
echo "Recent startup logs:"
docker-compose logs --tail=20 | grep -E "(Starting|Running|HTTP server|HTTPS server|port)" || echo "❌ No startup logs found"
echo ""

echo "📋 Step 5: Redirect Attempt Logs"
echo "--------------------------------"
echo "Recent redirect-related logs:"
docker-compose logs --tail=50 | grep -E "(Redirect|redirect|HTTP|HTTPS|Port|Scheme)" || echo "❌ No redirect logs found"
echo ""

echo "📋 Step 6: Test HTTP Access"
echo "----------------------------"
echo "Testing HTTP port 8090:"
curl -v -s http://localhost:8090/ 2>&1 | head -20 || echo "❌ HTTP port test failed"
echo ""

echo "📋 Step 7: Test HTTPS Access"
echo "-----------------------------"
echo "Testing HTTPS port 8443:"
curl -k -v -s https://localhost:8443/ 2>&1 | head -20 || echo "❌ HTTPS port test failed"
echo ""

echo "📋 Step 8: Container Process Check"
echo "----------------------------------"
echo "Checking if both Flask servers are running:"
docker-compose exec gpumon-app ps aux | grep -E "(python|Flask)" || echo "❌ Process check failed"
echo ""

echo "📋 Step 9: Network Configuration"
echo "--------------------------------"
echo "Container network info:"
docker-compose exec gpumon-app netstat -tlnp 2>/dev/null | grep -E "(8090|8443)" || echo "❌ Network check failed"
echo ""

echo "🔍 Diagnostic Complete!"
echo "======================"
echo ""
echo "💡 Common Issues and Solutions:"
echo "1. If HTTP_PORT not set: Check docker-compose.yml environment variables"
echo "2. If only one port listening: Dual-server setup may have failed"
echo "3. If no redirect logs: Redirect function may not be called"
echo "4. If container not running: Check docker-compose up --build -d"
echo ""
echo "📝 Next Steps:"
echo "- Check the output above for any ❌ errors"
echo "- Restart container if needed: docker-compose down && docker-compose up --build -d"
echo "- Check logs after restart: docker-compose logs -f"
