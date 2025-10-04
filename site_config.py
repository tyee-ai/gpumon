#!/usr/bin/env python3
"""
Shared site configuration for GPU monitoring system
"""

SITE_CONFIGS = {
    "DFW1": {
        "name": "Dallas-Fort Worth 1",
        "subnet": "172.16.4,10.19.21,10.19.31,10.19.41",
        "description": "Allen Texas Data Center - 508 ZGPU Nodes",
        "total_gpu_nodes": 508,
        "total_gpus": 4064,
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
                "start": "172.16.4.1",
                "end": "172.16.4.254",
                "count": 127
            },
            "Cluster 2": {
                "start": "10.19.21.1",
                "end": "10.19.21.254",
                "count": 127
            },
            "Cluster 3": {
                "start": "10.19.31.1",
                "end": "10.19.31.254",
                "count": 127
            },
            "Cluster 4": {
                "start": "10.19.41.1",
                "end": "10.19.41.254",
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
    },
    "IAD1": {
        "name": "Sterling, VA",
        "subnet": "10.14.11,10.14.21,10.14.31,10.14.41",
        "description": "Sterling, VA DC - 4064 GPUs",
        "total_gpu_nodes": 508,
        "total_gpus": 4064,
        "gpus_per_node": 8,
        "rrd_path": "/app/data_iad1",
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
            "Cluster 1&2": {
                "start": "10.14.11.1",
                "end": "10.14.21.127",
                "count": 254
            },
            "Cluster 3": {
                "start": "10.14.31.1",
                "end": "10.14.31.127",
                "count": 127
            },
            "Cluster 4": {
                "start": "10.14.41.1",
                "end": "10.14.41.127",
                "count": 127
            }
        }
    },
    "SEA1": {
        "name": "Seattle, WA 1",
        "subnet": "10.9.11,10.9.21,10.9.31,10.9.41,10.9.51,10.9.61,10.9.71,10.9.81",
        "description": "Seattle Washington Data Center - 1016 GPU Nodes",
        "total_gpu_nodes": 1016,
        "total_gpus": 8128,
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
                "start": "10.9.11.1",
                "end": "10.9.11.127",
                "count": 127
            },
            "Cluster 2": {
                "start": "10.9.21.1",
                "end": "10.9.21.127",
                "count": 127
            },
            "Cluster 3": {
                "start": "10.9.31.1",
                "end": "10.9.31.127",
                "count": 127
            },
            "Cluster 4": {
                "start": "10.9.41.1",
                "end": "10.9.41.127",
                "count": 127
            },
            "Cluster 5": {
                "start": "10.9.51.1",
                "end": "10.9.51.127",
                "count": 127
            },
            "Cluster 6": {
                "start": "10.9.61.1",
                "end": "10.9.61.127",
                "count": 127
            },
            "Cluster 7": {
                "start": "10.9.71.1",
                "end": "10.9.71.127",
                "count": 127
            },
            "Cluster 8": {
                "start": "10.9.81.1",
                "end": "10.9.81.127",
                "count": 127
            }
        }
    }
}

# Default site
DEFAULT_SITE = "DFW1"

# Helper functions
def get_site_by_subnet(subnet):
    """Get site configuration by subnet (e.g., '10.4' -> 'DFW2', '10.14.11' -> 'IAD1')"""
    for site_id, config in SITE_CONFIGS.items():
        # Check if subnet matches exactly
        if config["subnet"] == subnet:
            return site_id
        # Check if subnet is contained in the comma-separated list
        if ',' in config["subnet"]:
            subnets = [s.strip() for s in config["subnet"].split(',')]
            if subnet in subnets:
                return site_id
    return None

def get_site_by_numeric_id(numeric_id):
    """Get site configuration by numeric ID (e.g., '4' -> 'DFW2', '14' -> 'IAD1')"""
    # Try simple subnet first
    subnet = f"10.{numeric_id}"
    result = get_site_by_subnet(subnet)
    if result:
        return result
    
    # Try with .11 suffix for multi-subnet sites
    subnet = f"10.{numeric_id}.11"
    return get_site_by_subnet(subnet)


