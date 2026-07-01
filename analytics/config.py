"""
Config for Member 4 (AI Analytics).
Server address is read from the shared network.py at the project root.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from network import SERVER

BASE_URL          = SERVER
ANALYSIS_INTERVAL = 10
HISTORY_LIMIT     = 20

THRESHOLDS = {
    "cpu":  {"warning": 70,  "critical": 90},
    "ram":  {"warning": 75,  "critical": 90},
    "disk": {"warning": 80,  "critical": 95},
}
