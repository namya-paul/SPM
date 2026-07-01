"""
Sender module.
Handles sending the JSON payload to the backend server,
including retry logic and error logging if the server is unreachable.
"""

import logging
import time

import requests

from config import SERVER_URL, MAX_RETRIES, RETRY_DELAY, LOG_FILE


# Configure logging to write to a file as well as print to console.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(),
    ],
)


def send_data(payload):
    """
    Sends the given payload (dict) to SERVER_URL as JSON.

    If the request fails, it retries up to MAX_RETRIES times,
    waiting RETRY_DELAY seconds between attempts. If all retries
    fail, the error is logged and the function returns False so
    the main loop can continue running without crashing.
    """
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = requests.post(SERVER_URL, json=payload, timeout=60)
            response.raise_for_status()
            logging.info(f"Data sent successfully: {payload}")
            return True

        except requests.exceptions.RequestException as e:
            logging.warning(
                f"Attempt {attempt}/{MAX_RETRIES} failed to send data: {e}"
            )
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_DELAY)

    logging.error("All retry attempts failed. Skipping this reading.")
    return False
