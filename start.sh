#!/bin/bash

# Production startup script for GPU Monitor
echo "Starting GPU Monitor in production mode..."

# Set production environment variables
export FLASK_ENV=production
export FLASK_DEBUG=0

# Start the application with gunicorn for production
exec gunicorn --bind 0.0.0.0:5000 --workers 4 --worker-class sync --timeout 120 web_app:app
