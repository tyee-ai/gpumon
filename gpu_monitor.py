#!/usr/bin/env python3
"""
GPU RRD Monitor - Direct RRD file querying for GPU temperature analysis
Filters by throttled GPUs and temperature differentials
"""

import os
import sys
sys.path.append("/usr/lib/python3/dist-packages")
import rrdtool
from datetime import datetime, timedelta
from pathlib import Path
import argparse
import re

# ----------------------------
# Site Configuration
# ----------------------------
from site_config import SITE_CONFIGS, DEFAULT_SITE, get_site_by_numeric_id

# ----------------------------
# Argument Parsing
# ----------------------------
parser = argparse.ArgumentParser(description="Process GPU RRD sensor data.")
parser.add_argument("--base-path", type=str, help="Base path to RRD data (overrides site config)")
parser.add_argument("--site", type=str, default=DEFAULT_SITE, help="Site ID (DFW2, SITE2, SITE3, SITE4, or numeric: 4, 5, 6, 7)")
parser.add_argument("--full", action="store_true", help="If set, process full date range")
parser.add_argument("--start-date", type=str, help="Start date (YYYY-MM-DD) for full run")
parser.add_argument("--end-date", type=str, help="End date (YYYY-MM-DD) for full run")
args = parser.parse_args()

# ----------------------------
# Site Configuration Resolution
# ----------------------------
# Handle both numeric and string site IDs
if args.site.isdigit():
    # Convert numeric ID to site name
    site_name = get_site_by_numeric_id(args.site)
    if not site_name:
        print(f"❌ Error: Unknown numeric site '{args.site}'. Available numeric sites: 4, 5, 6, 7")
        sys.exit(1)
else:
    site_name = args.site

if site_name not in SITE_CONFIGS:
    print(f"❌ Error: Unknown site '{args.site}'. Available sites: {list(SITE_CONFIGS.keys())}")
    sys.exit(1)

site_config = SITE_CONFIGS[site_name]
subnet = site_config["subnet"]  # Use full subnet like "10.4" or "172.16.4"
base_path = args.base_path if args.base_path else site_config["rrd_path"]
gpu_map = site_config["gpu_map"]

print(f"🏢 Site: {site_config['name']} ({site_config['description']})")
print(f"🌐 Subnet: {site_config['subnet']}")
print(f"📁 RRD Path: {base_path}")
print(f"🎮 GPU Map: {len(gpu_map)} GPUs configured")

# ----------------------------
# Time Range Selection
# ----------------------------
def parse_date(date_str, default_date="2024-09-01"):
    """Parse date string in either MM/DD/YYYY or YYYY-MM-DD format"""
    if not date_str:
        date_str = default_date
    
    # Try MM/DD/YYYY format first (frontend format)
    try:
        return datetime.strptime(date_str, "%m/%d/%Y")
    except ValueError:
        # Try YYYY-MM-DD format (backend format)
        try:
            return datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            # Fallback to default
            return datetime.strptime(default_date, "%Y-%m-%d")

if args.full:
    start_time = int(parse_date(args.start_date).timestamp())
    end_time = int(parse_date(args.end_date, datetime.now().strftime("%m/%d/%Y")).timestamp()) if args.end_date else int(datetime.now().timestamp())
else:
    end_time = int(datetime.now().timestamp())
    start_time = int((datetime.now() - timedelta(days=7)).timestamp())

print(f"🔍 Time range for investigation:")
print(f"   Start: {datetime.fromtimestamp(start_time).isoformat()}")
print(f"   End:   {datetime.fromtimestamp(end_time).isoformat()}")

# ----------------------------
# Scan for GPU Devices Only
# ----------------------------
devices = []
# Create pattern based on subnet - handle multiple subnets separated by commas
if ',' in subnet:  # Multiple subnets like "10.19,172.16.4"
    subnet_patterns = []
    for sub in subnet.split(','):
        sub = sub.strip()
        if sub.count('.') == 1:  # Format like "10.19"
            subnet_patterns.append(rf"^{sub}\.\d+\.\d+$")
        else:  # Format like "172.16.4"
            subnet_patterns.append(rf"^{sub}\.\d+$")
    site_pattern = re.compile('|'.join(subnet_patterns))
else:  # Single subnet
    if subnet.count('.') == 1:  # Format like "10.4"
        site_pattern = re.compile(rf"^{subnet}\.\d+\.\d+$")
    else:  # Format like "172.16.4"
        site_pattern = re.compile(rf"^{subnet}\.\d+$")

print(f"🔎 Scanning for GPU devices in: {base_path}")

# First pass: find all devices matching site pattern
potential_devices = []
for entry in os.listdir(base_path):
    if site_pattern.match(entry):
        potential_devices.append(entry)

print(f"🔍 Found {len(potential_devices)} potential devices matching site pattern '{subnet}.*'")

# Second pass: filter for only devices that have GPU temperature data
for device in potential_devices:
    device_path = Path(base_path) / device
    
    # Check if this device has any GPU temperature RRD files
    has_gpu_data = False
    for oid, gpu_id in gpu_map.items():
        rrd_path = device_path / f"sensor-temperature-IDRAC-MIB-SMIv2-temperatureProbeReading-{oid}.rrd"
        if rrd_path.exists():
            has_gpu_data = True
            break
    
    # Only include devices that have GPU temperature data
    if has_gpu_data:
        devices.append(device)

print(f"✅ Found {len(devices)} GPU devices with temperature data")

device_paths = [Path(base_path) / dev for dev in devices]

# ----------------------------
# Collect Alerts
# ----------------------------
alerts = []
full_high_temp = []
full_suspicious = []
def find_nearest_cooler_gpu(temps, failed_gpu_id, failed_temp, max_temp_diff=10):
    """Find the nearest GPU with temperature <= max_temp_diff lower than the failed GPU"""
    nearest_gpu = None
    min_temp_diff = float("inf")
    
    for gpu_id, temp in temps.items():
        print(f"DEBUG: Checking {gpu_id}: {temp}°C, diff: {failed_temp - temp}°C")
        if gpu_id == failed_gpu_id:
            continue
        
        temp_diff = failed_temp - temp
        if 0 <= temp_diff <= max_temp_diff + 0.001:
            if temp_diff < min_temp_diff:
                min_temp_diff = temp_diff
                nearest_gpu = {"gpu_id": gpu_id, "temp": temp, "temp_diff": temp_diff}
    
    return nearest_gpu

latest_suspicious = {}
actual_start = None
actual_end = None
record_count = 0

for dev_path in device_paths:
    node = dev_path.name
    gpu_readings = {}

    for oid, gpu_id in gpu_map.items():
        rrd_path = dev_path / f"sensor-temperature-IDRAC-MIB-SMIv2-temperatureProbeReading-{oid}.rrd"

        if not rrd_path.exists():
            continue

        try:
            (start, end, step), names, rows = rrdtool.fetch(
                str(rrd_path), "MAX", "--start", str(start_time), "--end", str(end_time), "--resolution", "300"
            )
        except rrdtool.OperationalError:
            continue

        actual_start = min(actual_start, start) if actual_start else start
        actual_end = max(actual_end, end) if actual_end else end

        for i, row in enumerate(rows):
            ts = start + i * step
            temp = row[0]
            if temp is None:
                continue
            gpu_readings.setdefault(ts, {})[gpu_id] = temp

    for ts, temps in gpu_readings.items():
        if len(temps) < 8:
            continue
        
        record_count += 1
        avg_temp = sum(temps.values()) / len(temps)
        
        for gpu_id, temp in temps.items():
            if temp > 85:
                alert = {
                    "node": node,
                    "timestamp": datetime.fromtimestamp(ts).isoformat(),
                    "gpu_id": gpu_id,
                    "temp": round(temp, 2),
                    "reason": "Throttled"
                }
                if args.full:
                    full_high_temp.append(alert)
                else:
                    alerts.append(alert)
            elif avg_temp < 30 and temp > avg_temp + 8:
                # Find nearest GPU with temperature <= 10°C lower
                nearest_cooler = find_nearest_cooler_gpu(temps, gpu_id, temp, 10)
                cooler_info = nearest_cooler if nearest_cooler else {"gpu_id": "None", "temp": "N/A", "temp_diff": "N/A"}
                if args.full:
                    full_suspicious.append({
                        "node": node,
                        "timestamp": datetime.fromtimestamp(ts).isoformat(),
                        "gpu_id": gpu_id,
                        "temp": round(temp, 2),
                        "avg_temp": round(avg_temp, 2),
                        "reason": "Thermally Failed",
                        "nearest_cooler_gpu": cooler_info["gpu_id"],
                        "nearest_cooler_temp": cooler_info["temp"],
                        "nearest_cooler_diff": cooler_info["temp_diff"]
                    })
                else:
                    key = (node, gpu_id)
                    existing = latest_suspicious.get(key)
                    if not existing or ts > existing["ts"]:
                        latest_suspicious[key] = {
                            "node": node,
                            "timestamp": datetime.fromtimestamp(ts).isoformat(),
                            "gpu_id": gpu_id,
                            "temp": round(temp, 2),
                            "avg_temp": round(avg_temp, 2),
                            "reason": "Thermally Failed",
                            "nearest_cooler_gpu": cooler_info["gpu_id"],
                            "nearest_cooler_temp": cooler_info["temp"],
                            "nearest_cooler_diff": cooler_info["temp_diff"],
                            "ts": ts,
                            "count": existing["count"] + 1 if existing else 1
                        }
    alerts.extend(latest_suspicious.values())

if actual_start and actual_end:
    print(f"�� Actual RRD data range found:")
    print(f"   Earliest datapoint: {datetime.fromtimestamp(actual_start).isoformat()}")
    print(f"   Latest datapoint:   {datetime.fromtimestamp(actual_end).isoformat()}")

print(f"📈 Total records processed: {record_count}")
print(f"🚨 Total alerts generated: {len(alerts) if not args.full else len(full_high_temp) + len(full_suspicious)} (after deduplication)")

# ----------------------------
# Output Results to Screen

# Deduplicate alerts by IP and GPU
# ----------------------------
def deduplicate_alerts(alerts_list):
    """Deduplicate alerts by IP and GPU, keeping the most recent occurrence"""
    unique_alerts = {}
    for alert in alerts_list:
        key = (alert["node"], alert["gpu_id"])
        if key not in unique_alerts or alert["timestamp"] > unique_alerts[key]["timestamp"]:
            unique_alerts[key] = alert
    return list(unique_alerts.values())

# Deduplicate the alert lists
if args.full:
    # When using --full, keep ALL alerts to preserve history for duration calculations
    # Don't deduplicate - we want to see every throttling event
    pass
else:
    alerts = deduplicate_alerts(alerts)
# ----------------------------
if args.full:
    print("\n" + "=" * 60)
    print("🚨 FULL ANALYSIS RESULTS")
    print("=" * 60)
    
    if full_high_temp:
        print(f"\n🔥 THROTTLED GPUs ({len(full_high_temp)} unique IP+GPU combinations):")
        print("-" * 80)
        print("IP Address        GPU     Temperature  Date/Time")
        print("-" * 80)
        for alert in full_high_temp:
            timestamp = alert['timestamp'].replace("T", " ").split(".")[0]
            print(f"{alert['node']:<15} {alert['gpu_id']:<8} {alert['temp']:>6.1f}°C     {timestamp:<20}")
        print("-" * 80)
    
    if full_suspicious:
        print(f"\n⚠️  THERMALLY FAILED GPUs ({len(full_suspicious)} unique IP+GPU combinations):")
        print("-" * 80)
        print("IP Address        GPU     Temperature  Date/Time")
        print("-" * 80)
        for alert in full_suspicious:
            timestamp = alert['timestamp'].replace("T", " ").split(".")[0]
            print(f"{alert['node']:<15} {alert['gpu_id']:<8} {alert['temp']:>6.1f}°C     {timestamp:<20}")
        print("-" * 80)
    
    if not full_high_temp and not full_suspicious:
        print("✅ No alerts found in the specified time range")
else:
    print("\n" + "=" * 60)
    print("🚨 CURRENT ALERTS")
    print("=" * 60)
    
    if alerts:
        for alert in alerts:
            if alert["reason"] == "Throttled":
                print("🔥 {} {} {} Temp: {}°C".format(alert["timestamp"], alert["node"], alert["gpu_id"], alert["temp"]))
            elif alert["reason"] == "Thermally Failed":
                print("⚠️  {} {} {} Temp: {}°C (Avg: {}°C) - Nearest Cooler: {} at {}°C (diff: {}°C)".format(alert["timestamp"], alert["node"], alert["gpu_id"], alert["temp"], alert["avg_temp"], alert["nearest_cooler_gpu"], alert["nearest_cooler_temp"], alert["nearest_cooler_diff"]))
