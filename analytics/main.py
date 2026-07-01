"""
Main entry point for the AI Analytics module (Member 4).

Runs on a loop:
  1. Fetches the list of all monitored systems from the backend.
  2. For each system, fetches its latest reading and recent history.
  3. Runs threshold, trend, and anomaly analysis.
  4. POSTs any alerts back to the backend for the dashboard to display.

Run with:
    python main.py
"""

import logging
import time

import requests

from analytics import run_analysis
from config import BASE_URL, ANALYSIS_INTERVAL, THRESHOLDS, HISTORY_LIMIT

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("analytics.log"),
        logging.StreamHandler(),
    ],
)


def fetch(path):
    """GET from the backend API. Returns parsed JSON or None on failure."""
    try:
        resp = requests.get(f"{BASE_URL}{path}", timeout=5)
        resp.raise_for_status()
        return resp.json()
    except requests.RequestException as e:
        logging.warning(f"GET {path} failed: {e}")
        return None


def post_alert(alert):
    """POST a single alert dict to the backend."""
    try:
        resp = requests.post(f"{BASE_URL}/api/alerts", json=alert, timeout=5)
        resp.raise_for_status()
        logging.info(f"Alert posted [{alert['level'].upper()}] {alert['message']}")
    except requests.RequestException as e:
        logging.warning(f"Failed to post alert: {e}")


def analyse_all():
    """Fetch data for every system and run analysis."""
    systems = fetch("/api/systems")
    if not systems:
        logging.warning("No systems found or backend unreachable.")
        return

    for system_name in systems:
        # Latest reading (for threshold checks).
        latest_list = fetch("/api/metrics/latest")
        if not latest_list:
            continue

        latest = next(
            (s for s in latest_list if s["system_name"] == system_name), None
        )
        if not latest:
            continue

        # Historical readings (for trend + anomaly checks).
        history = fetch(f"/api/metrics/{system_name}?limit={HISTORY_LIMIT}")
        if not history:
            history = [latest]

        alerts = run_analysis(latest, history, THRESHOLDS)

        if alerts:
            for alert in alerts:
                post_alert(alert)
        else:
            logging.info(f"{system_name}: all metrics normal.")


def main():
    logging.info("Starting AI Analytics module.")
    logging.info(f"Backend: {BASE_URL} | Interval: {ANALYSIS_INTERVAL}s")

    while True:
        try:
            analyse_all()
        except Exception as e:
            logging.error(f"Unexpected error during analysis: {e}")

        time.sleep(ANALYSIS_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Analytics module stopped by user.")
