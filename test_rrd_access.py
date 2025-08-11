#!/usr/bin/env python3
"""
Test script to verify RRD file access in Docker container
"""
import os
import subprocess
import sys

def test_rrd_access():
    print("Testing RRD file access in Docker container...")
    
    # Test 1: Check if rrdtool is available
    try:
        result = subprocess.run(['rrdtool', '--version'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ rrdtool is available")
            print(f"   Version: {result.stdout.strip()}")
        else:
            print("❌ rrdtool command failed")
            print(f"   Error: {result.stderr}")
    except Exception as e:
        print(f"❌ Error running rrdtool: {e}")
    
    # Test 2: Check current user
    print(f"\nCurrent user: {os.getuid()}")
    print(f"Current user name: {os.getlogin()}")
    
    # Test 3: Check if we can access common RRD directories
    rrd_dirs = ['/var/lib/ganglia/rrds', '/var/lib/ganglia', '/app/data', '/data']
    
    for rrd_dir in rrd_dirs:
        if os.path.exists(rrd_dir):
            print(f"✅ Directory exists: {rrd_dir}")
            try:
                files = os.listdir(rrd_dir)
                print(f"   Contains {len(files)} files/directories")
                if files:
                    print(f"   Sample: {files[:3]}")
            except PermissionError:
                print(f"   ❌ Permission denied accessing {rrd_dir}")
            except Exception as e:
                print(f"   ❌ Error accessing {rrd_dir}: {e}")
        else:
            print(f"❌ Directory does not exist: {rrd_dir}")
    
    # Test 4: Try to run a simple rrdtool command
    print("\nTesting rrdtool info command...")
    try:
        # This should work even without actual RRD files
        result = subprocess.run(['rrdtool', 'info', '--help'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ rrdtool info command works")
        else:
            print("❌ rrdtool info command failed")
    except Exception as e:
        print(f"❌ Error testing rrdtool info: {e}")

if __name__ == "__main__":
    test_rrd_access()
