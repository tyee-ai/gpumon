# Port Configuration Summary

## 🎯 **Consistent Port 8090 Configuration**

All Docker configurations now use port **8090** consistently for both host and container.

## 📋 **Port Mapping Summary**

| File | Host Port | Container Port | Status |
|------|-----------|----------------|---------|
| `docker-compose.yml` | 8090 | 8090 | ✅ **Consistent** |
| `docker-compose.prod.yml` | 8090 | 8090 | ✅ **Updated** |
| `docker-compose.prod.privileged.yml` | 8090 | 8090 | ✅ **Updated** |
| `docker-compose.prod-alt.yml` | 8091 | 5000 | ⚠️ **Alternative** |

## 🔧 **Key Configuration Files**

### **Main Docker Compose** (`docker-compose.yml`)
```yaml
ports:
  - "8090:8090"  # Host:Container
environment:
  - FLASK_PORT=8090
  - FLASK_HOST=0.0.0.0
```

### **Production Docker Compose** (`docker-compose.prod.yml`)
```yaml
ports:
  - "8090:8090"  # Host:Container
environment:
  - FLASK_PORT=8090
  - FLASK_HOST=0.0.0.0
```

### **Privileged Production** (`docker-compose.prod.privileged.yml`)
```yaml
ports:
  - "8090:8090"  # Host:Container
environment:
  - FLASK_PORT=8090
  - FLASK_HOST=0.0.0.0
```

### **Alternative Production** (`docker-compose.prod-alt.yml`)
```yaml
ports:
  - "8091:5000"  # Alternative port for conflicts
```

## 🌐 **Access URLs**

- **Main Application**: http://localhost:8090
- **Alternative Port**: http://localhost:8091 (if 8090 is busy)

## 🔍 **Health Checks**

All health checks now verify the correct port:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8090/"]
```

## 📝 **Environment Variables**

```bash
FLASK_HOST=0.0.0.0      # Bind to all interfaces
FLASK_PORT=8090         # Container port
RRD_DATA_PATH=/app/data # RRD data mount point
```

## ✅ **Verification**

To verify port configuration:
```bash
# Check Docker Compose config
docker-compose config

# Check running containers
docker-compose ps

# Test health check
docker-compose exec gpumon curl -f http://localhost:8090/
```

## 🚀 **Benefits of Consistent Port 8090**

1. **No Port Translation**: Host port 8090 maps directly to container port 8090
2. **Simplified Configuration**: Same port number everywhere
3. **Easier Debugging**: No confusion about which port to use
4. **Consistent Documentation**: All references point to the same port
5. **Health Check Accuracy**: Health checks verify the actual service port

## 🔄 **Migration Notes**

- **Before**: Mixed port mappings (8090:5000, 8091:5000)
- **After**: Consistent port mappings (8090:8090, 8091:5000 for alternative)
- **Impact**: No breaking changes, just cleaner configuration
