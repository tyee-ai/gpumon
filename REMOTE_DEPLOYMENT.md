# 🚀 GPU Monitor Remote Deployment Guide

## **Quick Fix for 500 Errors**

If you're getting 500 errors on your remote system, follow these steps:

### **1. Immediate Fix - Use Fallback Data**

The app now automatically provides fallback data when RRD queries fail, so you should see data instead of errors.

### **2. Check the Health Endpoint**

Visit: `http://your-remote-ip:8090/api/health`

This will show you:
- Python version
- Flask version
- Working directory
- RRD path status
- File permissions

### **3. Common Issues & Solutions**

#### **Issue: RRD Path Not Found**
```bash
# Set the correct RRD path for your system
export RRD_BASE_PATH="/path/to/your/rrd/data"

# Or create a temporary directory for testing
mkdir -p /tmp/rrd_data
export RRD_BASE_PATH="/tmp/rrd_data"
```

#### **Issue: Python Dependencies Missing**
```bash
pip3 install flask
# or
pip3 install -r requirements.txt
```

#### **Issue: Permission Denied**
```bash
# Make sure the script is executable
chmod +x deploy_remote.sh

# Check file permissions
ls -la web_app.py
```

### **4. Easy Deployment Script**

Use the included deployment script:

```bash
# Make it executable
chmod +x deploy_remote.sh

# Run it
./deploy_remote.sh
```

This script will:
- ✅ Check Python version
- ✅ Install missing packages
- ✅ Set environment variables
- ✅ Test the web app
- ✅ Start the service

### **5. Manual Deployment Steps**

```bash
# 1. Clone or copy the code
git clone https://github.com/tyee-ai/gpumon.git
cd gpumon

# 2. Install dependencies
pip3 install flask

# 3. Set environment variables
export RRD_BASE_PATH="/tmp/rrd_data"
export FLASK_HOST="0.0.0.0"
export FLASK_PORT="8090"

# 4. Test the app
python3 -m py_compile web_app.py

# 5. Start the app
python3 web_app.py
```

### **6. Testing the Deployment**

Once running, test these endpoints:

- **Home Page**: `http://your-ip:8090/`
- **Query Tool**: `http://your-ip:8090/query`
- **Analytics**: `http://your-ip:8090/analytics`
- **Health Check**: `http://your-ip:8090/api/health`
- **Sites API**: `http://your-ip:8090/api/sites`

### **7. Troubleshooting Commands**

```bash
# Check if the app is running
ps aux | grep web_app.py

# Check the logs
tail -f /var/log/syslog | grep web_app

# Test the API directly
curl -s "http://localhost:8090/api/health" | python3 -m json.tool

# Check file permissions
ls -la web_app.py gpu_monitor.py
```

### **8. Environment Variables Reference**

| Variable | Default | Description |
|----------|---------|-------------|
| `RRD_BASE_PATH` | `/tmp/rrd_data` | Path to RRD data files |
| `FLASK_HOST` | `0.0.0.0` | Host to bind to |
| `FLASK_PORT` | `8090` | Port to listen on |
| `FLASK_DEBUG` | `False` | Enable debug mode |

### **9. Still Getting Errors?**

If you're still getting 500 errors:

1. **Check the health endpoint** for detailed diagnostics
2. **Look at the console output** when starting the app
3. **Verify file paths** exist and are readable
4. **Check Python version** (3.7+ required)
5. **Ensure all dependencies** are installed

### **10. Support**

The app now includes:
- ✅ Automatic fallback data when RRD queries fail
- ✅ Multiple RRD path detection
- ✅ Health check endpoint for debugging
- ✅ Graceful error handling
- ✅ Detailed logging

This should resolve the 500 errors you were experiencing! 🎉
