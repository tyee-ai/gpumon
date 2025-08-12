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
# Configurable Defaults
# ----------------------------
SITE = 4
DEFAULT_BASE_PATH = "/opt/docker/volumes/docker-observium_config/_data/rrd"

GPU_MAP = {
    "1.4": "GPU_21",
    "1.5": "GPU_22",
    "1.6": "GPU_23",
    "1.7": "GPU_24",
    "1.8": "GPU_25",
    "1.9": "GPU_26",
    "1.10": "GPU_27",
    "1.11": "GPU_28",
}

# ----------------------------
# Argument Parsing
# ----------------------------
parser = argparse.ArgumentParser(description="Process GPU RRD sensor data.")
parser.add_argument("--base-path", type=str, default=DEFAULT_BASE_PATH, help="Base path to RRD data")
parser.add_argument("--site", type=int, default=SITE, help="Site ID (used in device directory matching)")
parser.add_argument("--full", action="store_true", help="If set, process full date range")
parser.add_argument("--start-date", type=str, help="Start date (YYYY-MM-DD) for full run")
parser.add_argument("--end-date", type=str, help="End date (YYYY-MM-DD) for full run")
args = parser.parse_args()

# ----------------------------
# Time Range Selection
# ----------------------------
if args.full:
    start_time = int(datetime.strptime(args.start_date or "2024-09-01", "%Y-%m-%d").timestamp())
    end_time = int(datetime.strptime(args.end_date, "%Y-%m-%d").timestamp()) if args.end_date else int(datetime.now().timestamp())
else:
    end_time = int(datetime.now().timestamp())
    start_time = int((datetime.now() - timedelta(hours=1)).timestamp())

print(f"🔍 Time range for investigation:")
print(f"   Start: {datetime.fromtimestamp(start_time).isoformat()}")
print(f"   End:   {datetime.fromtimestamp(end_time).isoformat()}")

# ----------------------------
# Scan for Devices
# ----------------------------
devices = []
site_pattern = re.compile(rf"^10\.{args.site}\.\d+\.\d+$")

print(f"🔎 Scanning for devices in: {args.base_path}")

for entry in os.listdir(args.base_path):
    if site_pattern.match(entry):
        devices.append(entry)

print(f"✅ Found {len(devices)} devices matching site pattern '10.{args.site}.*.*'")

device_paths = [Path(args.base_path) / dev for dev in devices]

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
        print(f"DEBUG: Checking {gpu_id}: {temp}°C, diff: {failed_temp - temp}°C")
        if gpu_id == failed_gpu_id:
            continue
        
        temp_diff = failed_temp - temp

        if 0 <= temp_diff <= max_temp_diff + 0.001:
            if temp_diff < min_temp_diff:
                min_temp_diff = temp_diff
                nearest_gpu = {"gpu_id": gpu_id, "temp": temp, "temp_diff": temp_diff}
    

    return nearest_gpu
    """Find the nearest GPU with temperature <= max_temp_diff lower than the failed GPU"""
    nearest_gpu = None
    min_temp_diff = float("inf")
    
    for gpu_id, temp in temps.items():
        print(f"DEBUG: Checking {gpu_id}: {temp}°C, diff: {failed_temp - temp}°C")
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

    for oid, gpu_id in GPU_MAP.items():
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
            if temp > 80:
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
print(f"🚨 Total alerts generated: {len(alerts) if not args.full else len(full_high_temp) + len(full_suspicious)}")

# ----------------------------
# Output Results to Screen
# ----------------------------
if args.full:
    print("\n" + "=" * 60)
    print("🚨 FULL ANALYSIS RESULTS")
    print("=" * 60)
    
    if full_high_temp:
        print(f"\n🔥 THROTTLED GPUs ({len(full_high_temp)}):")
        for alert in full_high_temp:
            print(f"  • {alert['timestamp']} {alert['node']} {alert['gpu_id']} Temp: {alert['temp']}°C")
    
    if full_suspicious:
        print(f"\n⚠️  THERMALLY FAILED GPUs ({len(full_suspicious)}):")
        for alert in full_suspicious:
            print(f"  • {alert['timestamp']} {alert['node']} {alert['gpu_id']} Temp: {alert['temp']}°C (Avg: {alert['avg_temp']}°C)")
    
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
