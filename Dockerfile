FROM python:3.9-slim

# Install system dependencies including RRDtool and development headers
RUN apt-get update && apt-get install -y \
    rrdtool \
    librrd-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application files
COPY gpu_monitor.py .
COPY web_app.py .
COPY templates/ templates/
COPY static/ static/

# Make the scripts executable
RUN chmod +x gpu_monitor.py

# Create a volume mount point for RRD data
VOLUME ["/rrd-data"]

# Expose web port
EXPOSE 5000

# Set default command to run the web app
ENTRYPOINT ["python", "web_app.py"]
