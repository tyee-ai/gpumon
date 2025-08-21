# 🔒 GPU Monitor HTTPS Setup Guide

## 🚀 Overview

This guide covers setting up GPU Monitor to run over HTTPS instead of HTTP for enhanced security.

## 📋 Prerequisites

- Docker and Docker Compose installed
- OpenSSL available on your system
- Port 8443 available (or change in configuration)

## 🔧 Quick Setup

### 1. **Generate SSL Certificates**

```bash
# Make the script executable
chmod +x scripts/generate_ssl_certs.sh

# Generate self-signed certificates
./scripts/generate_ssl_certs.sh
```

This will create:
- `ssl/cert.pem` - SSL certificate
- `ssl/key.pem` - Private key

### 2. **Deploy with HTTPS**

```bash
# Use the HTTPS deployment script
./start_docker_https.sh

# Or manually with docker-compose
docker-compose up --build -d
```

### 3. **Access Your Application**

- **HTTPS (Main)**: https://localhost:8443
- **HTTP (Fallback)**: http://localhost:8090

## 🔒 SSL Configuration

### **Environment Variables**

```bash
# Enable SSL
FLASK_SSL=true

# SSL certificate paths
SSL_CERT=/app/ssl/cert.pem
SSL_KEY=/app/ssl/key.pem

# Port configuration
FLASK_PORT=8443
```

### **Certificate Details**

- **Type**: Self-signed
- **Validity**: 365 days
- **Key Size**: 2048 bits
- **Organization**: Voltage Park
- **Common Name**: gpumon.local

## 🚀 Production Deployment

### **Option 1: Automated Script**

```bash
./start_docker_https.sh
```

### **Option 2: Manual Docker Compose**

```bash
# Generate certificates first
./scripts/generate_ssl_certs.sh

# Start services
docker-compose up --build -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## 🔍 Verification

### **Check SSL Status**

```bash
# Check if container is running
docker-compose ps

# Test HTTPS endpoint
curl -k https://localhost:8443/

# Test HTTP fallback
curl http://localhost:8090/
```

### **Browser Access**

1. Navigate to https://localhost:8443
2. Accept the self-signed certificate warning
3. Your GPU Monitor is now running over HTTPS!

## 🛠️ Customization

### **Change Certificate Details**

Edit `scripts/generate_ssl_certs.sh`:

```bash
COUNTRY="US"
STATE="Texas"
LOCALITY="Dallas"
ORGANIZATION="Voltage Park"
COMMON_NAME="your-domain.com"
EMAIL="admin@yourdomain.com"
```

### **Change Ports**

Edit `docker-compose.yml`:

```yaml
ports:
  - "8090:8090"      # HTTP
  - "8443:8443"      # HTTPS (change as needed)
```

### **Use Your Own Certificates**

1. Place your certificates in the `ssl/` directory:
   - `ssl/cert.pem` - Your certificate
   - `ssl/key.pem` - Your private key

2. Update environment variables:
   ```bash
   SSL_CERT=/app/ssl/your-cert.pem
   SSL_KEY=/app/ssl/your-key.pem
   ```

## 🔒 Security Considerations

### **Self-Signed Certificates**

- **Pros**: Easy setup, no cost, immediate HTTPS
- **Cons**: Browser warnings, not trusted by default
- **Use Case**: Development, internal networks, testing

### **Production Certificates**

For production use, consider:
- **Let's Encrypt**: Free, trusted certificates
- **Commercial CAs**: Paid, widely trusted
- **Internal CA**: Enterprise environments

### **Certificate Renewal**

Self-signed certificates expire after 1 year. To renew:

```bash
# Remove old certificates
rm -rf ssl/

# Generate new ones
./scripts/generate_ssl_certs.sh

# Restart services
docker-compose restart
```

## 🚨 Troubleshooting

### **Common Issues**

#### 1. **Certificates Not Found**
```bash
# Check if certificates exist
ls -la ssl/

# Regenerate if missing
./scripts/generate_ssl_certs.sh
```

#### 2. **Port Already in Use**
```bash
# Check what's using port 8443
sudo netstat -tlnp | grep :8443

# Change port in docker-compose.yml
```

#### 3. **SSL Handshake Failed**
```bash
# Check certificate validity
openssl x509 -in ssl/cert.pem -text -noout

# Verify certificate and key match
openssl x509 -noout -modulus -in ssl/cert.pem | openssl md5
openssl rsa -noout -modulus -in ssl/key.pem | openssl md5
```

#### 4. **Container Won't Start**
```bash
# Check logs
docker-compose logs

# Verify SSL configuration
docker-compose config
```

### **Fallback to HTTP**

If HTTPS fails, the application will automatically fall back to HTTP:

```bash
# Force HTTP mode
export FLASK_SSL=false
docker-compose up --build -d
```

## 📚 Advanced Configuration

### **Custom SSL Context**

For advanced SSL configuration, modify `web_app.py`:

```python
ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
ssl_context.load_cert_chain(ssl_cert, ssl_key)
ssl_context.verify_mode = ssl.CERT_OPTIONAL

app.run(host=host, port=port, debug=debug, ssl_context=ssl_context)
```

### **Multiple Domains**

To support multiple domains, generate certificates with Subject Alternative Names (SANs):

```bash
# Create openssl config
cat > openssl.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = Texas
L = Dallas
O = Voltage Park
OU = IT
CN = gpumon.local

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = gpumon.local
DNS.2 = *.gpumon.local
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF

# Generate certificate with SANs
openssl req -new -x509 -key ssl/key.pem -out ssl/cert.pem -days 365 -config openssl.conf
```

## 🎯 Next Steps

After successful HTTPS setup:

1. **Test all functionality** over HTTPS
2. **Update any hardcoded HTTP URLs** in your application
3. **Configure reverse proxy** (nginx, Apache) if needed
4. **Set up monitoring** for certificate expiration
5. **Consider production certificates** for external access

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify SSL certificate files exist and are valid
3. Check Docker container logs
4. Ensure ports are not blocked by firewall
5. Verify OpenSSL is available on your system

---

**🔒 Your GPU Monitor is now running securely over HTTPS!**
