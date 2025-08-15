FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-rrdtool \
    python3-pip \
    librrd-dev \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python RRD tool module
RUN pip3 install rrdtool

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run as root to access RRD files that require elevated permissions
USER root

# Expose port
EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8090/ || exit 1

# Run the application
CMD ["python3", "web_app.py"]
