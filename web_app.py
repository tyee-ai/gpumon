#!/usr/bin/env python33
"""
GPU RRD Monitor Web Frontend
Provides web interface for GPU temperature analysis
"""

from flask import Flask, render_template, request, jsonify
import subprocess
import json
from datetime import datetime, timedelta
import os

app = Flask(__name__)

# Configuration
SITES = {
    "DFW2": {
        "name": "DFW2",
        "subnet": "10.4",
        "description": "Dallas-Fort Worth Data Center 2"
    }
}

DEFAULT_SITE = "DFW2"

@app.route('/')
def index():
    """Main dashboard page"""
    # Set default dates (last 7 days)
    end_date = datetime.now().strftime('%Y-%m-%d')
    start_date = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
    
    return render_template('index.html', 
                         sites=SITES, 
                         default_site=DEFAULT_SITE,
                         start_date=start_date,
                         end_date=end_date)

@app.route('/api/analysis', methods=['GET'])
def run_analysis():
    """Run GPU analysis based on parameters"""
    try:
        # Get parameters from request
        site = request.args.get('site', DEFAULT_SITE)
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        alert_type = request.args.get('alert_type', 'both')
        
        # Validate parameters
        if not all([site, start_date, end_date]):
            return jsonify({'error': 'Missing required parameters'}), 400
        
        if site not in SITES:
            return jsonify({'error': 'Invalid site'}), 400
        
        # Get site configuration
        site_config = SITES[site]
        site_id = site_config['subnet'].split('.')[1]  # Extract "4" from "10.4"
        
        # Build command for gpu_monitor.py
        cmd = [
            'python3', 'gpu_monitor.py',
            '--base-path', '/opt/docker/volumes/docker-observium_config/_data/rrd',
            '--site', site_id,
            '--full',
            '--start-date', start_date,
            '--end-date', end_date
        ]
        
        # Run the analysis
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,  # 5 minute timeout
            cwd='.'
        )
        
        if result.returncode != 0:
            return jsonify({
                'error': 'Analysis failed',
                'stderr': result.stderr
            }), 500
        
        # Parse the output to extract results
        output = result.stdout
        results = parse_analysis_output(output, alert_type)
        
        return jsonify({
            'success': True,
            'results': results,
            'raw_output': output,
            'site': site,
            'start_date': start_date,
            'end_date': end_date,
            'alert_type': alert_type
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Analysis timed out'}), 408
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def deduplicate_alerts(alerts):
    """Remove duplicate alerts based on IP and GPU only"""
    seen = set()
    unique_alerts = []
    
    for alert in alerts:
        # Create a key based on IP (device) and GPU only
        # This will show one record per unique IP+GPU combination
        key = (alert["device"], alert["gpu_id"])
        
        if key not in seen:
            seen.add(key)
            unique_alerts.append(alert)
    
    return unique_alerts

def aggregate_throttled_alerts(alerts):
    """Aggregate throttled alerts by GPU to show first/last date, temperature, and total days"""
    gpu_data = {}
    
    for alert in alerts:
        key = (alert["device"], alert["gpu_id"])
        if key not in gpu_data:
            gpu_data[key] = {
                "device": alert["device"],
                "gpu_id": alert["gpu_id"],
                "first_date": alert["timestamp"],
                "last_date": alert["timestamp"],
                "max_temp": alert["temp"],
                "count": 1
            }
        else:
            # Update last date, max temp, and increment count
            if alert["timestamp"] < gpu_data[key]["first_date"]:
                gpu_data[key]["first_date"] = alert["timestamp"]
            if alert["timestamp"] > gpu_data[key]["last_date"]:
                gpu_data[key]["last_date"] = alert["timestamp"]
            if alert["temp"] > gpu_data[key]["max_temp"]:
                gpu_data[key]["max_temp"] = alert["temp"]
            gpu_data[key]["count"] += 1
    
    # Convert back to list and calculate days
    aggregated = []
    for data in gpu_data.values():
        # Calculate days between first and last date
        try:
            from datetime import datetime
            first_date = datetime.fromisoformat(data["first_date"].replace("Z", "+00:00"))
            last_date = datetime.fromisoformat(data["last_date"].replace("Z", "+00:00"))
            days_throttled = (last_date - first_date).days + 1  # +1 to include both start and end dates
        except:
            days_throttled = data["count"]
        
        aggregated.append({
            "device": data["device"],
            "gpu_id": data["gpu_id"],
            "first_date": data["first_date"],
            "last_date": data["last_date"],
            "max_temp": data["max_temp"],
            "days_throttled": days_throttled
        })
    
    return aggregated
    """Remove duplicate alerts based on IP, GPU, and data (timestamp)"""
    seen = set()
    unique_alerts = []
    
    for alert in alerts:
        # Create a key based on IP (device), GPU, and timestamp
        # Extract IP from device name (e.g., "device-10.4.1.1" -> "10.4.1.1")
        ip = alert["device"].replace("device-", "")
        key = (ip, alert["gpu_id"], alert["timestamp"])
        
        if key not in seen:
            seen.add(key)
            unique_alerts.append(alert)
    
    return unique_alerts

def aggregate_throttled_alerts(alerts):
    """Aggregate throttled alerts by GPU to show first/last date, temperature, and total days"""
    gpu_data = {}
    
    for alert in alerts:
        key = (alert["device"], alert["gpu_id"])
        if key not in gpu_data:
            gpu_data[key] = {
                "device": alert["device"],
                "gpu_id": alert["gpu_id"],
                "first_date": alert["timestamp"],
                "last_date": alert["timestamp"],
                "max_temp": alert["temp"],
                "count": 1
            }
        else:
            # Update last date, max temp, and increment count
            if alert["timestamp"] < gpu_data[key]["first_date"]:
                gpu_data[key]["first_date"] = alert["timestamp"]
            if alert["timestamp"] > gpu_data[key]["last_date"]:
                gpu_data[key]["last_date"] = alert["timestamp"]
            if alert["temp"] > gpu_data[key]["max_temp"]:
                gpu_data[key]["max_temp"] = alert["temp"]
            gpu_data[key]["count"] += 1
    
    # Convert back to list and calculate days
    aggregated = []
    for data in gpu_data.values():
        # Calculate days between first and last date
        try:
            from datetime import datetime
            first_date = datetime.fromisoformat(data["first_date"].replace("Z", "+00:00"))
            last_date = datetime.fromisoformat(data["last_date"].replace("Z", "+00:00"))
            days_throttled = (last_date - first_date).days + 1  # +1 to include both start and end dates
        except:
            days_throttled = data["count"]
        
        aggregated.append({
            "device": data["device"],
            "gpu_id": data["gpu_id"],
            "first_date": data["first_date"],
            "last_date": data["last_date"],
            "max_temp": data["max_temp"],
            "days_throttled": days_throttled
        })
    
    return aggregated


def parse_analysis_output(output, alert_type):
    """Parse the analysis output and filter by alert type"""
    results = {
        'throttled': [],
        'thermally_failed': [],
        'summary': {}
    }
    
    lines = output.split('\n')
    current_section = None
    
    for line in lines:
        line = line.strip()
        
        # Detect sections
        if 'THROTTLED GPUs' in line:
            current_section = 'throttled'
            continue
        elif 'THERMALLY FAILED GPUs' in line:
            current_section = 'thermally_failed'
            continue
        elif 'Summary:' in line:
            current_section = 'summary'
            continue
        
        # Parse throttled GPUs
        if current_section == 'throttled' and line.startswith('•'):
            if alert_type in ['throttled', 'both']:
                # Parse: "• 2024-08-09T22:30:00 device-10.4.1.1 GPU_21 Temp: 85.5°C"
                parts = line.split(' ')
                if len(parts) >= 6:
                    timestamp = parts[1]
                    device = parts[2]
                    gpu_id = parts[3]
                    temp = parts[5].replace('°C', '')
                    
                    results['throttled'].append({
                        'timestamp': timestamp,
                        'device': device,
                        'gpu_id': gpu_id,
                        'temp': float(temp),
                        'type': 'Throttled'
                    })
        
        # Parse thermally failed GPUs
        elif current_section == 'thermally_failed' and line.startswith('•'):
            if alert_type in ['thermally_failed', 'both']:
                # Parse: "• 2024-08-09T22:30:00 device-10.4.1.1 GPU_21 Temp: 45.2°C (Avg: 32.1°C)"
                parts = line.split(' ')
                if len(parts) >= 6:
                    timestamp = parts[1]
                    device = parts[2]
                    gpu_id = parts[3]
                    temp = parts[5].replace('°C', '')
                    avg_temp = parts[7].replace('°C', '').replace('(', '').replace(')', '')
                    
                    results['thermally_failed'].append({
                        'timestamp': timestamp,
                        'device': device,
                        'gpu_id': gpu_id,
                        'temp': float(temp),
                        'avg_temp': float(avg_temp),
                        'type': 'Thermally Failed'
                    })
        
        # Parse summary
        elif current_section == 'summary' and ':' in line:
            if 'Total devices analyzed' in line:
                results['summary']['total_devices'] = line.split(':')[1].strip()
            elif 'Throttled:' in line:
                results['summary']['throttled_count'] = line.split(':')[1].strip()
            elif 'Suspicious:' in line:
                results['summary']['suspicious_count'] = line.split(':')[1].strip()
            elif 'Normal:' in line:
                results['summary']['normal_count'] = line.split(':')[1].strip()
    

    # Apply deduplication to both alert types
    if alert_type in ["throttled", "both"]:
        results["throttled"] = aggregate_throttled_alerts(results["throttled"])
    if alert_type in ["thermally_failed", "both"]:
        results["thermally_failed"] = deduplicate_alerts(results["thermally_failed"])
    

    return results

@app.route('/api/sites')
def get_sites():
    """Get available sites"""
    return jsonify(SITES)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
