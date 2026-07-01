"""
Config for Member 1 (Monitoring Agent).
Server address is read from the shared network.py at the project root.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from network import SERVER

SERVER_URL    = f"{SERVER}/api/metrics"
SEND_INTERVAL = 5
MAX_RETRIES   = 3
RETRY_DELAY   = 2
LOG_FILE      = "agent.log"
