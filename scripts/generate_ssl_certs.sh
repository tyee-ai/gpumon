#!/bin/bash
# Generate Self-Signed SSL Certificates for GPU Monitor
# This script creates SSL certificates for HTTPS support

set -e

echo "🔒 Generating SSL Certificates for GPU Monitor"
echo "=============================================="

# Create SSL directory
SSL_DIR="./ssl"
mkdir -p "$SSL_DIR"

# Certificate details
COUNTRY="US"
STATE="Texas"
LOCALITY="Dallas"
ORGANIZATION="Voltage Park"
ORGANIZATIONAL_UNIT="IT"
COMMON_NAME="gpumon.local"
EMAIL="admin@voltagepark.com"

# Certificate validity (days)
VALIDITY_DAYS=365

echo "📋 Certificate Details:"
echo "   Country: $COUNTRY"
echo "   State: $STATE"
echo "   Locality: $LOCALITY"
echo "   Organization: $ORGANIZATION"
echo "   Common Name: $COMMON_NAME"
echo "   Validity: $VALIDITY_DAYS days"
echo ""

# Generate private key
echo "🔑 Generating private key..."
openssl genrsa -out "$SSL_DIR/key.pem" 2048

# Generate certificate signing request (CSR)
echo "📝 Generating certificate signing request..."
openssl req -new -key "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.csr" -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"

# Generate self-signed certificate
echo "✅ Generating self-signed certificate..."
openssl x509 -req -in "$SSL_DIR/cert.csr" -signkey "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.pem" -days "$VALIDITY_DAYS"

# Remove CSR file (not needed)
rm "$SSL_DIR/cert.csr"

# Set proper permissions
chmod 600 "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"

echo ""
echo "🎉 SSL Certificates Generated Successfully!"
echo "=========================================="
echo "   Private Key: $SSL_DIR/key.pem"
echo "   Certificate: $SSL_DIR/cert.pem"
echo "   Validity: $VALIDITY_DAYS days"
echo ""
echo "📋 Next Steps:"
echo "   1. Certificates are ready for use"
echo "   2. Run './start_docker_https.sh' to start with HTTPS"
echo "   3. Or manually: docker-compose up --build (or docker compose up --build)"
echo "   4. Access your app at: https://localhost:8443"
echo "   5. Accept the self-signed certificate warning in your browser"
echo ""
echo "⚠️  Note: Self-signed certificates will show browser warnings."
echo "   For production, use certificates from a trusted CA."
echo ""
echo "🔒 HTTPS is now enabled for GPU Monitor!"
