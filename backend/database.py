"""
Database module — SQLite schema and helpers.
Tables: metrics, alerts, users
"""

import sqlite3
import hashlib
from contextlib import contextmanager
from config import DB_PATH


@contextmanager
def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def _hash(password):
    return hashlib.sha256(password.encode()).hexdigest()


def init_db():
    with get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                system_name TEXT NOT NULL,
                ip_address TEXT,
                os TEXT,
                logged_in_user TEXT,
                cpu REAL,
                ram REAL,
                disk REAL,
                network REAL,
                timestamp TEXT NOT NULL,
                received_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_system_time
            ON metrics (system_name, received_at)
        """)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                system_name TEXT NOT NULL,
                metric TEXT NOT NULL,
                level TEXT NOT NULL,
                message TEXT NOT NULL,
                value REAL,
                created_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                system_name TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)


# ---------- metrics -------------------------------------------------

def insert_metric(data):
    with get_connection() as conn:
        conn.execute("""
            INSERT INTO metrics
                (system_name, ip_address, os, logged_in_user,
                 cpu, ram, disk, network, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            data.get("system_name"),
            data.get("ip_address"),
            data.get("os"),
            data.get("logged_in_user"),
            data.get("cpu"),
            data.get("ram"),
            data.get("disk"),
            data.get("network"),
            data.get("timestamp"),
        ))
        # Auto-link user to this system_name if they exist and aren't linked yet
        logged_in_user = data.get("logged_in_user")
        system_name = data.get("system_name")
        if logged_in_user and system_name:
            conn.execute("""
    UPDATE users SET system_name = ?
    WHERE LOWER(username) = LOWER(?) AND (system_name IS NULL OR system_name = '')
""", (system_name, logged_in_user))


def get_latest_for_all_systems():
    with get_connection() as conn:
        rows = conn.execute("""
            SELECT m.* FROM metrics m
            INNER JOIN (
                SELECT system_name, MAX(received_at) AS max_time
                FROM metrics GROUP BY system_name
            ) latest
            ON m.system_name = latest.system_name
            AND m.received_at = latest.max_time
            ORDER BY m.system_name
        """).fetchall()
        return [dict(row) for row in rows]


def get_latest_for_user(username):
    """Returns the latest metric reading for the system linked to this user."""
    with get_connection() as conn:
        row = conn.execute("""
            SELECT m.* FROM metrics m
            INNER JOIN users u ON m.system_name = u.system_name
            WHERE u.username = ?
            ORDER BY m.received_at DESC LIMIT 1
        """, (username,)).fetchone()
        return dict(row) if row else None


def get_history(system_name, limit=100):
    with get_connection() as conn:
        rows = conn.execute("""
            SELECT * FROM (
                SELECT * FROM metrics WHERE system_name = ?
                ORDER BY received_at DESC LIMIT ?
            ) ORDER BY received_at ASC
        """, (system_name, limit)).fetchall()
        return [dict(row) for row in rows]


def get_history_for_user(username, limit=50):
    """Returns metric history for the system linked to this user."""
    with get_connection() as conn:
        rows = conn.execute("""
            SELECT m.* FROM metrics m
            INNER JOIN users u ON m.system_name = u.system_name
            WHERE u.username = ?
            ORDER BY m.received_at DESC LIMIT ?
        """, (username, limit)).fetchall()
        return [dict(row) for row in reversed(rows)]


def get_all_system_names():
    with get_connection() as conn:
        rows = conn.execute("""
            SELECT DISTINCT system_name FROM metrics ORDER BY system_name
        """).fetchall()
        return [row["system_name"] for row in rows]


# ---------- alerts --------------------------------------------------

def insert_alert(data):
    with get_connection() as conn:
        conn.execute("""
            INSERT INTO alerts (system_name, metric, level, message, value)
            VALUES (?, ?, ?, ?, ?)
        """, (
            data.get("system_name"),
            data.get("metric"),
            data.get("level"),
            data.get("message"),
            data.get("value"),
        ))


def get_recent_alerts(limit=50):
    with get_connection() as conn:
        rows = conn.execute("""
            SELECT * FROM alerts ORDER BY created_at DESC LIMIT ?
        """, (limit,)).fetchall()
        return [dict(row) for row in rows]


def get_alerts_for_user(username, limit=20):
    """Returns alerts for the system linked to this user."""
    with get_connection() as conn:
        rows = conn.execute("""
            SELECT a.* FROM alerts a
            INNER JOIN users u ON a.system_name = u.system_name
            WHERE u.username = ?
            ORDER BY a.created_at DESC LIMIT ?
        """, (username, limit)).fetchall()
        return [dict(row) for row in rows]


# ---------- users ---------------------------------------------------

def register_user(username, password):
    """Returns (True, 'ok') or (False, 'error message')."""
    try:
        with get_connection() as conn:
            conn.execute("""
                INSERT INTO users (username, password_hash)
                VALUES (?, ?)
            """, (username.lower(), _hash(password)))
        return True, "registered"
    except sqlite3.IntegrityError:
        return False, "Username already exists"


def login_user(username, password):
    """Returns user row dict or None if credentials are wrong."""
    with get_connection() as conn:
        row = conn.execute("""
            SELECT * FROM users
            WHERE username = ? AND password_hash = ?
        """, (username.lower(), _hash(password))).fetchone()
        return dict(row) if row else None
