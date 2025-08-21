#!/usr/bin/env python3
"""
Debug script to test RRD data access and gpu_monitor.py execution
"""

import os
import subprocess
import sys

def test_rrd_paths():
    """Test all possible RRD paths"""
    print("🔍 Testing RRD Paths")
    print("=" * 50)
    
    possible_paths = [
        "/opt/docker/volumes/docker-observium_config/_data/rrd",
        "/app/data",
        "/app/rrd_data",
        "/home/drew/src/gpumon/rrd_data",
        "/tmp/rrd_data"
    ]
    
    for path in possible_paths:
        exists = os.path.exists(path)
        readable = os.access(path, os.R_OK) if exists else False
        print(f"Path: {path}")
        print(f"  Exists: {exists}")
        print(f"  Readable: {readable}")
        
        if exists and readable:
            try:
                entries = os.listdir(path)
                gpu_entries = [e for e in entries if e.startswith('10.4.')]
                print(f"  Total entries: {len(entries)}")
                print(f"  GPU entries (10.4.*): {len(gpu_entries)}")
                if gpu_entries:
                    print(f"  Sample GPU entries: {gpu_entries[:5]}")
            except Exception as e:
                print(f"  Error listing: {e}")
        print()

def test_gpu_monitor():
    """Test gpu_monitor.py execution"""
    print("🔍 Testing gpu_monitor.py")
    print("=" * 50)
    
    # Test with different RRD paths
    test_paths = [
        "/opt/docker/volumes/docker-observium_config/_data/rrd",
        "/app/data",
        "/app/rrd_data"
    ]
    
    for rrd_path in test_paths:
        if os.path.exists(rrd_path):
            print(f"Testing with RRD path: {rrd_path}")
            
            cmd = [
                'python3', 'gpu_monitor.py',
                '--base-path', rrd_path,
                '--site', '4',
                '--start-date', '2025-08-01',
                '--end-date', '2025-08-15'
            ]
            
            try:
                print(f"Running: {' '.join(cmd)}")
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=60,
                    cwd='.'
                )
                
                print(f"Return code: {result.returncode}")
                print(f"Stdout length: {len(result.stdout)}")
                print(f"Stderr length: {len(result.stderr)}")
                
                if result.stdout:
                    print("Stdout preview:")
                    print(result.stdout[:500] + "..." if len(result.stdout) > 500 else result.stdout)
                
                if result.stderr:
                    print("Stderr:")
                    print(result.stderr)
                
            except subprocess.TimeoutExpired:
                print("Command timed out")
            except Exception as e:
                print(f"Error: {e}")
            
            print("-" * 30)

def test_environment():
    """Test environment variables and current working directory"""
    print("🔍 Environment Information")
    print("=" * 50)
    
    print(f"Current working directory: {os.getcwd()}")
    print(f"Python executable: {sys.executable}")
    print(f"Python version: {sys.version}")
    
    env_vars = ['RRD_BASE_PATH', 'FLASK_PORT', 'FLASK_HOST', 'FLASK_DEBUG']
    for var in env_vars:
        value = os.environ.get(var, 'Not set')
        print(f"{var}: {value}")
    
    print()
    print("Files in current directory:")
    try:
        files = os.listdir('.')
        for f in sorted(files):
            if f.endswith('.py') or f in ['gpu_monitor.py', 'web_app.py']:
                print(f"  {f}")
    except Exception as e:
        print(f"Error listing files: {e}")

if __name__ == "__main__":
    print("🚀 GPU Monitor RRD Debug Script")
    print("=" * 60)
    print()
    
    test_environment()
    print()
    test_rrd_paths()
    print()
    test_gpu_monitor()
    
    print("✅ Debug script completed")
