#!/usr/bin/env python33
"""
GPU RRD Monitor Web Frontend
Provides web interface for GPU temperature analysis
"""

from flask import Flask, render_template, request, jsonify, make_response, send_file, session, redirect, url_for
import subprocess
import json
from datetime import datetime, timedelta
def get_site_and_cluster(ip_address):
    """Determine site and cluster based on IP address"""
    try:
        ip_obj = ipaddress.ip_address(ip_address)
        
        # Check each site's IP ranges
        for site_code, site_info in SITES.items():
            for cluster_name, cluster_info in site_info.get("ip_ranges", {}).items():
                start_ip = ipaddress.ip_address(cluster_info["start"])
                end_ip = ipaddress.ip_address(cluster_info["end"])
                
                if start_ip <= ip_obj <= end_ip:
                    return site_code, cluster_name
        
        # If no match found, return unknown
        return "Unknown", "Unknown"
        
    except ValueError:
        return "Unknown", "Unknown"

def sort_alerts_by_date_and_cluster(alerts):
    """Sort alerts by date (newest first) and then by cluster"""
    def sort_key(alert):
        try:
            # Parse timestamp to datetime object for sorting
            dt = datetime.strptime(alert["first_date"], "%Y-%m-%d %H:%M:%S")
            # Return tuple for sorting: (cluster, -timestamp) to sort by cluster first, then newest first
            return (alert.get("cluster", "Unknown"), -dt.timestamp())
        except:
            return (alert.get("cluster", "Unknown"), 0)
    
    return sorted(alerts, key=sort_key)

import os
import ipaddress
import re

app = Flask(__name__)

# Authentication configuration
app.secret_key = os.environ.get('FLASK_SECRET_KEY', 'gpumon-secret-key-change-in-production')
CREDENTIALS = {
    'gpumon': 'v0lt4g3p4rk'
}

# Configuration
SITES = {
    "DFW2": {
        "name": "Dallas-Fort Worth 2",
        "subnet": "10.4",
        "description": "Dallas-Fort Worth Data Center 2",
        "total_gpu_nodes": 254,
        "total_gpus": 2032,
        "gpus_per_node": 8,
        "rrd_path": "/opt/docker/volumes/docker-observium_config/_data/rrd",
        "ip_ranges": {
            "Cluster 1": {
                "start": "10.4.11.1",
                "end": "10.4.11.127",
                "count": 127
            },
            "Cluster 2": {
                "start": "10.4.21.1",
                "end": "10.4.21.127",
                "count": 127
            }
        }
    },
    "SITE2": {
        "name": "Site 2",
        "subnet": "10.5",
        "description": "Site 2 Data Center",
        "total_gpu_nodes": 128,
        "total_gpus": 1024,
        "gpus_per_node": 8,
        "rrd_path": "/opt/docker/volumes/site2_observium_config/_data/rrd",
        "ip_ranges": {
            "Cluster 1": {
                "start": "10.5.11.1",
                "end": "10.5.11.127",
                "count": 127
            }
        }
    },
    "SITE3": {
        "name": "Site 3",
        "subnet": "10.6",
        "description": "Site 3 Data Center",
        "total_gpu_nodes": 96,
        "total_gpus": 768,
        "gpus_per_node": 8,
        "rrd_path": "/opt/docker/volumes/site3_observium_config/_data/rrd",
        "ip_ranges": {
            "Cluster 1": {
                "start": "10.6.11.1",
                "end": "10.6.11.96",
                "count": 96
            }
        }
    },
    "SITE4": {
        "name": "Site 4",
        "subnet": "10.7",
        "description": "Site 4 Data Center",
        "total_gpu_nodes": 64,
        "total_gpus": 512,
        "gpus_per_node": 8,
        "rrd_path": "/opt/docker/volumes/site4_observium_config/_data/rrd",
        "ip_ranges": {
            "Cluster 1": {
                "start": "10.7.11.1",
                "end": "10.7.11.64",
                "count": 64
            }
        }
    }
}

DEFAULT_SITE = "DFW2"

def login_required(f):
    """Decorator to require login for protected routes"""
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    decorated_function.__name__ = f.__name__
    return decorated_function

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Login page and authentication"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if username in CREDENTIALS and CREDENTIALS[username] == password:
            session['logged_in'] = True
            session['username'] = username
            return redirect(url_for('home'))
        else:
            return render_template('login.html', error='Invalid username or password')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """Logout and clear session"""
    session.clear()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def home():
    """Home page with cluster status dashboard"""
    response = make_response(render_template('home.html', sites=SITES, default_site=DEFAULT_SITE))
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.route('/query')
@login_required
def index():
    """Main dashboard page"""
    # Set default dates (last 7 days)
    end_date = datetime.now().strftime('%Y-%m-%d')
    start_date = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
    
    response = make_response(render_template('index.html', 
                         sites=SITES, 
                         default_site=DEFAULT_SITE,
                         start_date=start_date,
                         end_date=end_date))
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.route('/analytics')
@login_required
def analytics():
    """Analytics page with GPU throttling breakdown"""
    response = make_response(render_template('analytics.html', sites=SITES, default_site=DEFAULT_SITE))
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.route('/test')
@login_required
def test_page():
    """Simple test page for debugging frontend issues"""
    return send_file('simple_test.html')

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
        
        # Use site-specific RRD path if available, otherwise fall back to environment variable
        site_rrd_path = site_config.get('rrd_path')
        possible_rrd_paths = [
            site_rrd_path,  # Site-specific RRD path
            os.environ.get("RRD_BASE_PATH"),  # Environment variable
            "/app/data",  # Docker container path (mounted volume)
            "/opt/docker/volumes/docker-observium_config/_data/rrd",  # Docker volume path
            "/app/rrd_data",  # Container path
            "/home/drew/src/gpumon/rrd_data",  # Local development path
            "/tmp/rrd_data"  # Fallback path
        ]
        
        rrd_base_path = None
        for path in possible_rrd_paths:
            if path and os.path.exists(path):
                rrd_base_path = path
                print(f"Debug: Using RRD path for {site}: {rrd_base_path}")
                break
        
        if not rrd_base_path:
            # If no path exists, use the site-specific path and let it fail gracefully
            rrd_base_path = site_rrd_path or possible_rrd_paths[1] or "/tmp/rrd_data"
            print(f"Debug: No RRD path found for {site}, using: {rrd_base_path}")
        
        cmd = [
            'python3', 'gpu_monitor.py',
            "--base-path", rrd_base_path,
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
            print(f"Debug: gpu_monitor.py failed with return code {result.returncode}")
            print(f"Debug: stderr: {result.stderr}")
            
            # Return fallback data instead of error for better user experience
            fallback_results = {
                'summary': {
                    'total_devices': 253,
                    'planned_gpu_nodes': 254,
                    'planned_total_gpus': 2032,
                    'throttled_count': 0,
                    'suspicious_count': 0,
                    'normal_count': 'N/A',
                    'total_records': 0,
                    'total_alerts': 0
                },
                'throttled': [],
                'thermally_failed': []
            }
            
            return jsonify({
                'success': True,
                'results': fallback_results,
                'site': site,
                'start_date': start_date,
                'end_date': end_date,
                'alert_type': alert_type,
                'warning': 'Using fallback data due to RRD query failure'
            })
        
        # Parse the output to extract results
        output = result.stdout
        results = parse_analysis_output(output, alert_type)
        
        # Sort alerts by date and cluster
        if "throttled" in results and results["throttled"]:
            results["throttled"] = sort_alerts_by_date_and_cluster(results["throttled"])
        if "thermally_failed" in results and results["thermally_failed"]:
            results["thermally_failed"] = sort_alerts_by_date_and_cluster(results["thermally_failed"])
        
        return jsonify({
            'success': True,
            'results': results,
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

def format_throttled_alerts(alerts):
    """Format throttled alerts to show accurate duration calculations from full history"""
    gpu_data = {}
    
    for alert in alerts:
        key = (alert["device"], alert["gpu_id"])
        if key not in gpu_data:
            gpu_data[key] = {
                "site": alert.get("site", "Unknown"),
                "cluster": alert.get("cluster", "Unknown"),
                "device": alert["device"],
                "gpu_id": alert["gpu_id"],
                "first_alert": alert["timestamp"],  # First time this GPU alerted
                "last_alert": alert["timestamp"],   # Last time this GPU alerted
                "max_temp": alert["temp"],          # Highest temperature seen
                "alert_count": 1,                   # Count of alerts for this GPU
                "all_timestamps": [alert["timestamp"]]  # Track all timestamps
            }
        else:
            # Track the earliest and latest alert times for this GPU
            if alert["timestamp"] < gpu_data[key]["first_alert"]:
                gpu_data[key]["first_alert"] = alert["timestamp"]
            if alert["timestamp"] > gpu_data[key]["last_alert"]:
                gpu_data[key]["last_alert"] = alert["timestamp"]
            if alert["temp"] > gpu_data[key]["max_temp"]:
                gpu_data[key]["max_temp"] = alert["temp"]
            gpu_data[key]["alert_count"] += 1
            gpu_data[key]["all_timestamps"].append(alert["timestamp"])
    
    # Convert to list format with accurate duration calculations
    formatted = []
    for data in gpu_data.values():
        # Calculate actual days between first and last alert
        try:
            from datetime import datetime
            first_date = datetime.fromisoformat(data["first_alert"].replace("Z", "+00:00"))
            last_date = datetime.fromisoformat(data["last_alert"].replace("Z", "+00:00"))
            days_throttled = (last_date - first_date).days + 1  # +1 to include both start and end dates
            
            # Debug output for multi-day alerts
            if days_throttled > 1:
                print(f"Debug: Multi-day alert detected for {data['device']} {data['gpu_id']}")
                print(f"  First alert: {data['first_alert']}")
                print(f"  Last alert: {data['last_alert']}")
                print(f"  Days throttled: {days_throttled}")
                print(f"  Total alerts: {data['alert_count']}")
                
        except Exception as e:
            print(f"Warning: Could not parse dates for {data['device']} {data['gpu_id']}: {e}")
            days_throttled = 1  # Fallback to 1 day
        
        formatted.append({
            "device": data["device"],
            "site": data["site"],
            "cluster": data["cluster"],
            "gpu_id": data["gpu_id"],
            "first_date": data["first_alert"],      # First time this GPU alerted
            "last_date": data["last_alert"],        # Last time this GPU alerted
            "max_temp": data["max_temp"],           # Highest temperature seen
            "days_throttled": days_throttled,       # Actual calculated duration
            "alert_count": data["alert_count"],     # Total number of alerts for this GPU
            "note": f"Throttled for {days_throttled} day{'s' if days_throttled > 1 else ''}"
        })
    
    return formatted
    
    # Convert back to list and calculate days
    aggregated = []
    for data in gpu_data.values():
        # Calculate days between first and last alert times
        try:
            from datetime import datetime
            # Handle different timestamp formats
            first_alert_str = data["first_alert"]
            last_alert_str = data["last_alert"]
            
            # Convert ISO format timestamps to datetime objects
            if 'T' in first_alert_str:
                first_alert = datetime.fromisoformat(first_alert_str.replace("Z", "+00:00"))
            else:
                # Handle "YYYY-MM-DD HH:MM:SS" format
                first_alert = datetime.strptime(first_alert_str, "%Y-%m-%d %H:%M:%S")
            
            if 'T' in last_alert_str:
                last_alert = datetime.fromisoformat(last_alert_str.replace("Z", "+00:00"))
            else:
                # Handle "YYYY-MM-DD HH:MM:SS" format
                last_alert = datetime.strptime(last_alert_str, "%Y-%m-%d %H:%M:%S")
            
            # Validate that first_alert is before or equal to last_alert
            if first_alert > last_alert:
                print(f"Warning: First alert ({first_alert}) is after last alert ({last_alert}) for {data['device']} {data['gpu_id']}")
                # Swap the dates
                first_alert, last_alert = last_alert, first_alert
                data["first_alert"], data["last_alert"] = data["last_alert"], data["first_alert"]
            
            # Calculate the difference in days
            time_diff = last_alert - first_alert
            days_throttled = time_diff.days + 1  # +1 to include both start and end dates
            
            # Since gpu_monitor.py deduplicates to only show latest alerts,
            # we need to estimate the actual duration based on alert count
            # If we have multiple alerts but they're all on the same day,
            # it likely means the GPU has been throttled for longer
            if data["alert_count"] > 1 and days_throttled == 1:
                # Estimate duration based on alert count and frequency
                # Assume alerts occur roughly every 8 hours (3 per day)
                estimated_days = max(1, data["alert_count"] // 3)
                days_throttled = estimated_days
                print(f"Debug: Estimated duration for {data['device']} {data['gpu_id']}: {data['alert_count']} alerts over ~{estimated_days} days")
            
            # Debug output for multi-day alerts
            if days_throttled > 1:
                print(f"Debug: Multi-day alert detected for {data['device']} {data['gpu_id']}")
                print(f"  First alert: {first_alert} ({first_alert_str})")
                print(f"  Last alert: {last_alert} ({last_alert_str})")
                print(f"  Time difference: {time_diff}")
                print(f"  Days throttled: {days_throttled}")
                print(f"  Total alerts: {data['alert_count']}")
            
            # Validate the calculation makes sense
            if days_throttled > 365:  # More than a year seems suspicious
                print(f"Warning: Suspiciously long alert duration for {data['device']} {data['gpu_id']}: {days_throttled} days")
                # Recalculate using alert count as fallback
                days_throttled = min(data["alert_count"], 30)  # Cap at 30 days
            
            # Ensure minimum of 1 day
            if days_throttled < 1:
                days_throttled = 1
                
        except Exception as e:
            print(f"Warning: Could not parse dates for {data['device']} {data['gpu_id']}: {e}")
            # Fallback to alert count if date parsing fails
            days_throttled = data["alert_count"]
        
        aggregated.append({
            "device": data["device"],
            "site": data["site"],
            "cluster": data["cluster"],
            "gpu_id": data["gpu_id"],
            "first_date": data["first_alert"],  # First time this GPU alerted
            "last_date": data["last_alert"],    # Last time this GPU alerted
            "max_temp": data["max_temp"],
            "days_throttled": days_throttled,
            "alert_count": data["alert_count"]  # Total number of alerts for this GPU
        })
    
    return aggregated


def deduplicate_alerts(alerts):
    """Remove duplicate alerts based on IP, GPU, and timestamp"""
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


def format_thermally_failed_alerts(alerts):
    """Aggregate thermally failed alerts by IP+GPU combination"""
    if not alerts:
        return []
    
    # Group alerts by device (IP) and GPU ID
    gpu_data = {}
    
    for alert in alerts:
        key = (alert["device"], alert["gpu_id"])
        
        if key not in gpu_data:
            gpu_data[key] = {
                "device": alert["device"],
                "site": alert["site"],
                "cluster": alert["cluster"],
                "gpu_id": alert["gpu_id"],
                "first_alert": alert["timestamp"],
                "last_alert": alert["timestamp"],
                "max_temp": alert["temp"],
                "alert_count": 1
            }
        else:
            # Update existing entry
            gpu_data[key]["alert_count"] += 1
            
            # Update first alert if this is earlier
            if alert["timestamp"] < gpu_data[key]["first_alert"]:
                gpu_data[key]["first_alert"] = alert["timestamp"]
            
            # Update last alert if this is later
            if alert["timestamp"] > gpu_data[key]["last_alert"]:
                gpu_data[key]["last_alert"] = alert["timestamp"]
            
            # Update max temperature if this is higher
            if alert["temp"] > gpu_data[key]["max_temp"]:
                gpu_data[key]["max_temp"] = alert["temp"]
    
    # Convert to list format with accurate duration calculations
    formatted = []
    for data in gpu_data.values():
        # Calculate actual days between first and last alert
        try:
            from datetime import datetime
            first_date = datetime.fromisoformat(data["first_alert"].replace("Z", "+00:00"))
            last_date = datetime.fromisoformat(data["last_alert"].replace("Z", "+00:00"))
            days_failed = (last_date - first_date).days + 1  # +1 to include both start and end dates
            
            # Debug output for multi-day alerts
            if days_failed > 1:
                print(f"Debug: Multi-day thermally failed alert detected for {data['device']} {data['gpu_id']}")
                print(f"  First alert: {data['first_alert']}")
                print(f"  Last alert: {data['last_alert']}")
                print(f"  Days failed: {days_failed}")
                print(f"  Total alerts: {data['alert_count']}")
                
        except Exception as e:
            print(f"Warning: Could not parse dates for {data['device']} {data['gpu_id']}: {e}")
            days_failed = 1  # Fallback to 1 day
        
        formatted.append({
            "device": data["device"],
            "site": data["site"],
            "cluster": data["cluster"],
            "gpu_id": data["gpu_id"],
            "first_date": data["first_alert"],      # First time this GPU failed
            "last_date": data["last_alert"],        # Last time this GPU failed
            "max_temp": data["max_temp"],           # Highest temperature seen
            "days_failed": days_failed,             # Actual calculated duration
            "alert_count": data["alert_count"],     # Total number of alerts for this GPU
            "note": f"Failed for {days_failed} day{'s' if days_failed > 1 else ''}"
        })
    
    return formatted


def parse_analysis_output(output, alert_type):
    """Parse the analysis output and filter by alert type"""
    print(f"Debug: Starting parse_analysis_output with alert_type: {alert_type}")
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
            print(f"Debug: Detected THROTTLED GPUs section")
            continue
        elif 'THERMALLY FAILED GPUs' in line:
            current_section = 'thermally_failed'
            print(f"Debug: Detected THERMALLY FAILED GPUs section")
            continue
        
        # Parse throttled GPUs
        if current_section == 'throttled' and line and not line.startswith('---') and not line.startswith('IP Address') and not line.startswith('GPU') and not line.startswith('Temperature') and not line.startswith('Date/Time'):
            print(f"Debug: Processing line in throttled section: '{line}'")
            if alert_type in ['throttled', 'both']:
                # Parse table format: "10.4.11.36      GPU_25     90.7°C     2025-03-24 00:00:00"
                parts = line.split()
                if len(parts) >= 4:
                    device = parts[0]
                    gpu_id = parts[1]
                    temp = parts[2].replace('°C', '').replace('\u00b0C', '').replace('\u00b0', '').replace('°', '')
                    timestamp = parts[3] + ' ' + parts[4]
                    site, cluster = get_site_and_cluster(device)
                    
                    # Debug: Log the parsed timestamp format
                    print(f"Debug: Parsed throttled alert - Device: {device}, GPU: {gpu_id}, Temp: {temp}, Timestamp: '{timestamp}'")
                    
                    results['throttled'].append({
                        'timestamp': timestamp,
                        'device': device,
                        'gpu_id': gpu_id,
                        'temp': float(temp),
                        'type': 'Throttled',
                        'site': site,
                        'cluster': cluster
                    })
        
        # Parse thermally failed GPUs
        elif current_section == 'thermally_failed' and line and not line.startswith('---') and not line.startswith('IP Address') and not line.startswith('GPU') and not line.startswith('Temperature') and not line.startswith('Date/Time'):
            if alert_type in ['thermally_failed', 'both']:
                # Parse table format: "10.4.11.36      GPU_25     90.7°C     2025-03-24 00:00:00"
                parts = line.split()
                if len(parts) >= 4:
                    device = parts[0]
                    gpu_id = parts[1]
                    temp = parts[2].replace('°C', '').replace('\u00b0C', '').replace('\u00b0', '').replace('°', '')
                    timestamp = parts[3] + ' ' + parts[4]
                    
                    # For thermally failed alerts, we need to get the average temp from the data
                    # Since the full output doesn't include avg_temp in the table, we'll set it to N/A
                    avg_temp = None
                    
                    site, cluster = get_site_and_cluster(device)
                    results['thermally_failed'].append({
                        'timestamp': timestamp,
                        'device': device,
                        'gpu_id': gpu_id,
                        'temp': float(temp),
                        'avg_temp': avg_temp,
                        'type': 'Thermally Failed',
                        'site': site,
                        'cluster': cluster
                    })
        
    

    # Apply deduplication to both alert types
    if alert_type in ["throttled", "both"]:
        # For throttled alerts, we'll show the most recent alert for each GPU
        # Since gpu_monitor.py already deduplicates to show latest, we just need to format the data
        results["throttled"] = format_throttled_alerts(results["throttled"])
    if alert_type in ["thermally_failed", "both"]:
        # For thermally failed alerts, aggregate by IP+GPU combination
        results["thermally_failed"] = format_thermally_failed_alerts(results["thermally_failed"])
    
    # Generate summary from the actual data
    print(f"Debug: Summary generation - throttled: {len(results['throttled'])}, thermally_failed: {len(results['thermally_failed'])}")
    results['summary'] = {
        'total_devices': 253,  # Default to 253 GPU devices (from our infrastructure)
        'planned_gpu_nodes': 254,  # Planned infrastructure
        'planned_total_gpus': 2032,  # Planned total GPUs (254 * 8)
        'throttled_count': len(results["throttled"]) if "throttled" in results else 0,
        'suspicious_count': len(results["thermally_failed"]) if "thermally_failed" in results else 0,
        'normal_count': 'N/A',  # We don't have this info from the current output
        'total_records': 0,  # Will be updated from parsing
        'total_alerts': 0   # Will be updated from parsing
    }
    print(f"Debug: Summary counts - throttled_count: {results['summary']['throttled_count']}, suspicious_count: {results['summary']['suspicious_count']}")
    
    # Try to extract additional information from raw output
    print(f"Debug: Starting to parse {len(lines)} lines for additional info")
    for line in lines:
        print(f"Debug: Processing line: {line.strip()}")
        if 'Found' in line and 'GPU devices with temperature data' in line:
            # Extract number from "Found 253 GPU devices with temperature data"
            import re
            match = re.search(r'Found (\d+) GPU devices with temperature data', line)
            if match:
                results['summary']['total_devices'] = int(match.group(1))
                print(f"Debug: Updated total_devices to {results['summary']['total_devices']}")
        elif 'Found' in line and 'devices matching site pattern' in line:
            # Fallback: Extract number from "Found 516 potential devices matching site pattern '10.4.*.*'"
            import re
            match = re.search(r'Found (\d+) potential devices', line)
            if match:
                # This is the total potential devices, not GPU devices
                pass
        elif 'Total records processed:' in line:
            # Extract number from "📈 Total records processed: 12345"
            match = re.search(r'Total records processed: (\d+)', line)
            if match:
                results['summary']['total_records'] = int(match.group(1))
                print(f"Debug: Updated total_records to {results['summary']['total_records']}")
        elif 'Total alerts generated:' in line:
            # Extract number from "📈 Total alerts generated: 12345"
            match = re.search(r'Total alerts generated: (\d+)', line)
            if match:
                results['summary']['total_alerts'] = int(match.group(1))
                print(f"Debug: Updated total_alerts to {results['summary']['total_alerts']}")
    
        print(f"Debug: Final summary: {results['summary']}")
    
    # Ensure we always have the correct infrastructure values
    if results['summary']['total_devices'] == 'N/A' or results['summary']['total_devices'] == 0:
        results['summary']['total_devices'] = 253  # Default GPU devices count
    
    if results['summary']['total_records'] == 0:
        results['summary']['total_records'] = results['summary'].get('total_records', 0)
    
    if results['summary']['total_alerts'] == 0:
        results['summary']['total_alerts'] = results['summary'].get('total_alerts', 0)
    
    print(f"Debug: Final corrected summary: {results['summary']}")
    
    return results

@app.route('/api/sites')
def get_sites():
    """Get available sites"""
    return jsonify(SITES)

@app.route('/api/health')
def health_check():
    """Health check endpoint for remote deployment debugging"""
    try:
        health_info = {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'environment': {
                'python_version': sys.version,
                'working_directory': os.getcwd(),
                'rrd_base_path': os.environ.get("RRD_BASE_PATH", "Not set"),
                'gpu_monitor_exists': os.path.exists('gpu_monitor.py'),
                'rrd_paths': []
            }
        }
        
        # Check possible RRD paths
        possible_rrd_paths = [
            os.environ.get("RRD_BASE_PATH"),
            "/opt/docker/volumes/docker-observium_config/_data/rrd",
            "/app/rrd_data",
            "/home/drew/src/gpumon/rrd_data",
            "/tmp/rrd_data"
        ]
        
        for path in possible_rrd_paths:
            if path:
                health_info['environment']['rrd_paths'].append({
                    'path': path,
                    'exists': os.path.exists(path),
                    'readable': os.access(path, os.R_OK) if os.path.exists(path) else False
                })
        
        return jsonify(health_info)
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    # Get host and port from environment variables or use defaults
    host = os.environ.get('FLASK_HOST', '0.0.0.0')
    port = int(os.environ.get('FLASK_PORT', 8090))
    debug = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    
    # SSL configuration
    ssl_enabled = os.environ.get('FLASK_SSL', 'True').lower() == 'true'
    ssl_cert = os.environ.get('SSL_CERT', '/app/ssl/cert.pem')
    ssl_key = os.environ.get('SSL_KEY', '/app/ssl/key.pem')
    
    print(f"Starting GPU Monitor on {host}:{port}")
    print(f"Debug mode: {debug}")
    print(f"SSL enabled: {ssl_enabled}")
    
    if ssl_enabled:
        # Check if SSL certificates exist
        if os.path.exists(ssl_cert) and os.path.exists(ssl_key):
            print(f"Using SSL certificates: {ssl_cert}, {ssl_key}")
            app.run(host=host, port=port, debug=debug, ssl_context=(ssl_cert, ssl_key))
        else:
            print(f"SSL enabled but certificates not found at {ssl_cert}, {ssl_key}")
            print("Falling back to HTTP mode")
            app.run(host=host, port=port, debug=debug)
    else:
        app.run(host=host, port=port, debug=debug)
