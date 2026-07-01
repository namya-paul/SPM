"""
Main entry point for the monitoring agent.
Sends system metrics including the logged-in Windows username
so the backend can match data to the correct user.
"""

import time
from datetime import datetime, timezone

from config import SEND_INTERVAL
from collector import get_system_info, MetricsCollector
from sender import send_data
import logging


def main():
    system_info = get_system_info()
    collector = MetricsCollector()

    logging.info(f"Starting monitoring agent on {system_info['hostname']}")
    logging.info(f"Logged in as: {system_info['logged_in_user']}")

    collector.get_metrics()  # warm-up

    while True:
        metrics = collector.get_metrics()

        payload = {
            "system_name":    system_info["hostname"],
            "ip_address":     system_info["ip_address"],
            "os":             system_info["os"],
            "logged_in_user": system_info["logged_in_user"],
            "cpu":            metrics["cpu"],
            "ram":            metrics["ram"],
            "disk":           metrics["disk"],
            "network":        metrics["network"],
            "timestamp":      datetime.now(timezone.utc).isoformat(),
        }

        send_data(payload)
        time.sleep(SEND_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Monitoring agent stopped by user.")
