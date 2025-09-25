#!/usr/bin/env python3
"""
Shared site configuration for GPU monitoring system
"""

SITE_CONFIGS = {
    "DFW1": {
        "name": "Dallas-Fort Worth 1",
        "subnet": "10.19.21,10.19.31",
        "description": "Allen Texas Data Center - 254 ZGPU Nodes",
        "total_gpu_nodes": 254,
        "total_gpus": 2032,
        "gpus_per_node": 8,
        "rrd_path": "/opt/docker/volumes/docker-observium_config/_data/rrd",
        "gpu_map": {
            "1.4": "GPU_21",
            "1.5": "GPU_22",
            "1.6": "GPU_23",
            "1.7": "GPU_24", 
            "1.8": "GPU_25",
            "1.9": "GPU_26",
            "1.10": "GPU_27",
            "1.11": "GPU_28",
        },
        "ip_ranges": {
            "Cluster 1": {
                "start": "10.19.21.1",
                "end": "10.19.21.254",
                "count": 127
            },
            "Cluster 2": {
                "start": "10.19.31.1",
                "end": "10.19.31.254",
                "count": 127
            }
        }
    },
    "DFW2": {
        "name": "Dallas-Fort Worth 2",
        "subnet": "10.4",
        "description": "Dallas-Fort Worth Data Center 2",
        "total_gpu_nodes": 254,
        "total_gpus": 2032,
        "gpus_per_node": 8,
        "rrd_path": "/opt/docker/volumes/docker-observium_config/_data/rrd",
        "gpu_map": {
            "1.4": "GPU_21",
            "1.5": "GPU_22", 
            "1.6": "GPU_23",
            "1.7": "GPU_24",
            "1.8": "GPU_25",
            "1.9": "GPU_26",
            "1.10": "GPU_27",
            "1.11": "GPU_28",
        },
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
    }
}

# Default site
DEFAULT_SITE = "DFW2"

# Helper functions
def get_site_by_subnet(subnet):
    """Get site configuration by subnet (e.g., '10.4' -> 'DFW2')"""
    for site_id, config in SITE_CONFIGS.items():
        if config["subnet"] == subnet:
            return site_id
    return None

def get_site_by_numeric_id(numeric_id):
    """Get site configuration by numeric ID (e.g., '4' -> 'DFW2')"""
    subnet = f"10.{numeric_id}"
    return get_site_by_subnet(subnet)


