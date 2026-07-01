"""
Collector module.
Responsible for gathering system identification info and
real-time resource usage metrics (CPU, RAM, disk, network).
"""

import os
import socket
import platform
import time
import psutil


def get_system_info():
    """
    Returns static information about the machine:
    hostname, IP address, operating system, and the currently
    logged-in Windows/OS username.
    """
    hostname = socket.gethostname()

    try:
        ip_address = socket.gethostbyname(hostname)
    except socket.gaierror:
        ip_address = "127.0.0.1"

    os_info = f"{platform.system()} {platform.release()}"

    # Get the currently logged-in user (works on Windows, Mac, Linux).
    logged_in_user = (
        os.environ.get("USERNAME")
        or os.environ.get("USER")
        or "unknown"
    ).lower()

    return {
        "hostname": hostname,
        "ip_address": ip_address,
        "os": os_info,
        "logged_in_user": logged_in_user,
    }


class MetricsCollector:
    """
    Collects live system metrics.

    Network usage is calculated as a rate (bytes per second) by
    comparing total bytes sent/received between two points in time,
    so this class keeps track of the previous reading.
    """

    def __init__(self):
        net = psutil.net_io_counters()
        self._last_bytes_sent = net.bytes_sent
        self._last_bytes_recv = net.bytes_recv
        self._last_time = time.time()

    def get_metrics(self):
        cpu_percent = psutil.cpu_percent(interval=1)
        ram_percent = psutil.virtual_memory().percent
        disk_percent = psutil.disk_usage("/").percent

        net = psutil.net_io_counters()
        now = time.time()

        elapsed = now - self._last_time
        if elapsed <= 0:
            elapsed = 1

        bytes_sent_diff = net.bytes_sent - self._last_bytes_sent
        bytes_recv_diff = net.bytes_recv - self._last_bytes_recv

        network_kbps = round(
            (bytes_sent_diff + bytes_recv_diff) / elapsed / 1024, 2
        )

        self._last_bytes_sent = net.bytes_sent
        self._last_bytes_recv = net.bytes_recv
        self._last_time = now

        return {
            "cpu": cpu_percent,
            "ram": ram_percent,
            "disk": disk_percent,
            "network": network_kbps,
        }