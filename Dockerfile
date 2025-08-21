FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    rrdtool \
    python3-rrdtool \
    python3-pip \
    librrd-dev \
    build-essential \
    curl \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Python RRD tool module
RUN pip3 install rrdtool

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create SSL directory
RUN mkdir -p /app/ssl

# Copy application code
COPY . .

# Run as root to access RRD files that require elevated permissions
USER root

# Expose both HTTP and HTTPS ports
EXPOSE 8090 8443

# Health check for HTTPS (with -k flag to ignore self-signed cert)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f -k https://localhost:8443/ || curl -f http://localhost:8090/ || exit 1

# Run the application
CMD ["python3", "web_app.py"]
