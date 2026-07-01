"""
Analytics engine for Member 4.

Three levels of intelligence, in increasing sophistication:

1. Threshold alerts  — flag when a metric is simply too high right now.
2. Trend detection   — flag when a metric is steadily rising even if
                       it hasn't crossed the threshold yet.
3. Anomaly detection — flag when a reading is statistically unusual
                       compared to that system's own recent history
                       (uses z-score so it adapts per machine).
"""

import numpy as np


# ---------- helpers -------------------------------------------------

def _values(history, metric):
    """Extract a list of floats for `metric` from a list of reading dicts."""
    return [float(r.get(metric, 0)) for r in history]


# ---------- 1. threshold alerts -------------------------------------

def check_thresholds(latest, thresholds):
    """
    Compare the latest reading against fixed warning/critical thresholds.

    Returns a (possibly empty) list of alert dicts.
    """
    alerts = []
    system = latest.get("system_name", "Unknown")

    for metric, levels in thresholds.items():
        value = float(latest.get(metric, 0))

        if value >= levels["critical"]:
            alerts.append({
                "system_name": system,
                "metric": metric,
                "level": "critical",
                "value": value,
                "message": (
                    f"{metric.upper()} usage is critically high "
                    f"({value:.1f}%) on {system}."
                ),
            })
        elif value >= levels["warning"]:
            alerts.append({
                "system_name": system,
                "metric": metric,
                "level": "warning",
                "value": value,
                "message": (
                    f"{metric.upper()} usage is elevated "
                    f"({value:.1f}%) on {system}."
                ),
            })

    return alerts


# ---------- 2. trend detection --------------------------------------

def check_trends(history, metric, system_name, window=6, min_rise=15):
    """
    Detect a sustained upward trend over the last `window` readings.

    A trend is flagged when the metric has risen by at least `min_rise`
    percentage points from the start of the window to the latest reading,
    and the linear regression slope is positive — meaning it's been
    consistently climbing, not just jumping around.

    Returns an alert dict or None.
    """
    if len(history) < window:
        return None

    vals = np.array(_values(history, metric)[-window:])
    rise = vals[-1] - vals[0]

    if rise < min_rise:
        return None

    # Linear regression: positive slope confirms a real trend.
    x = np.arange(len(vals))
    slope = np.polyfit(x, vals, 1)[0]

    if slope <= 0:
        return None

    return {
        "system_name": system_name,
        "metric": metric,
        "level": "warning",
        "value": round(float(vals[-1]), 1),
        "message": (
            f"{metric.upper()} on {system_name} has been rising steadily "
            f"(+{rise:.1f}% over the last {window} readings). "
            f"Current: {vals[-1]:.1f}%."
        ),
    }


# ---------- 3. anomaly detection (z-score) --------------------------

def check_anomaly(history, metric, system_name, z_threshold=2.5):
    """
    Flag the latest reading if it is statistically unusual compared to
    that system's own recent history.

    Uses a z-score: how many standard deviations is the latest value
    from the mean of recent readings? A z-score above `z_threshold`
    (default 2.5) is flagged as an anomaly.

    This adapts per machine — a server that normally sits at 80% CPU
    won't be flagged, but a desktop that suddenly spikes from 10% to
    70% will be.

    Returns an alert dict or None.
    """
    if len(history) < 5:
        return None

    vals = np.array(_values(history, metric))
    mean = np.mean(vals[:-1])   # exclude the latest value from baseline
    std  = np.std(vals[:-1])
    latest_val = vals[-1]

    if std < 1:      # too little variance to be meaningful
        return None

    z = abs(latest_val - mean) / std

    if z < z_threshold:
        return None

    direction = "spike" if latest_val > mean else "drop"

    return {
        "system_name": system_name,
        "metric": metric,
        "level": "warning",
        "value": round(float(latest_val), 1),
        "message": (
            f"Anomalous {metric.upper()} {direction} detected on "
            f"{system_name}: {latest_val:.1f}% "
            f"(normal ~{mean:.1f}%, z={z:.1f})."
        ),
    }


# ---------- main entry point ----------------------------------------

def run_analysis(latest, history, thresholds):
    """
    Run all three analysis stages for one system and return a
    deduplicated list of alert dicts.

    `latest`     — most recent metric reading dict for this system
    `history`    — list of recent reading dicts (oldest first)
    `thresholds` — dict from config.py
    """
    system = latest.get("system_name", "Unknown")
    alerts = []
    seen   = set()   # deduplicate by (metric, level, type)

    # 1. Thresholds
    for alert in check_thresholds(latest, thresholds):
        key = (alert["metric"], alert["level"], "threshold")
        if key not in seen:
            seen.add(key)
            alerts.append(alert)

    # 2. Trends + 3. Anomalies for each metric
    for metric in thresholds:
        trend = check_trends(history, metric, system)
        if trend:
            key = (metric, trend["level"], "trend")
            if key not in seen:
                seen.add(key)
                alerts.append(trend)

        anomaly = check_anomaly(history, metric, system)
        if anomaly:
            key = (metric, anomaly["level"], "anomaly")
            if key not in seen:
                seen.add(key)
                alerts.append(anomaly)

    return alerts
