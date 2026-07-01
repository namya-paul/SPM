"""
Backend Flask API — updated with user auth and per-user metrics.
"""

from datetime import datetime, timezone
from flask import Flask, request, jsonify
import database
from config import HOST, PORT, OFFLINE_THRESHOLD_SECONDS, DEFAULT_HISTORY_LIMIT

app = Flask(__name__)


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return response


@app.route("/", methods=["GET"])
def health_check():
    return jsonify({"status": "ok", "message": "Monitoring backend is running"})


# ---------- Auth endpoints ------------------------------------------

@app.route("/api/register", methods=["POST"])
def register():
    """
    Register a new user.
    The system_name will be auto-linked once the agent on their PC
    starts sending data with a matching logged_in_user field.

    Body: { "username": "merry", "password": "abc123" }
    """
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "").strip()

    if not username or not password:
        return jsonify({"error": "Username and password are required"}), 400
    if len(password) < 4:
        return jsonify({"error": "Password must be at least 4 characters"}), 400

    ok, msg = database.register_user(username, password)
    if ok:
        return jsonify({"status": "registered", "username": username}), 201
    return jsonify({"error": msg}), 409


@app.route("/api/login", methods=["POST"])
def login():
    """
    Log in and get back the user's info + their linked system.

    Body: { "username": "merry", "password": "abc123" }
    """
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "").strip()

    user = database.login_user(username, password)
    if not user:
        return jsonify({"error": "Invalid username or password"}), 401

    return jsonify({
        "status": "ok",
        "username": user["username"],
        "system_name": user.get("system_name"),
    })


# ---------- Metric endpoints ----------------------------------------

@app.route("/api/metrics", methods=["POST"])
def receive_metrics():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid or missing JSON body"}), 400
    if "system_name" not in data:
        return jsonify({"error": "system_name is required"}), 400
    if "timestamp" not in data:
        data["timestamp"] = datetime.now(timezone.utc).isoformat()

    database.insert_metric(data)
    return jsonify({"status": "received"}), 201


@app.route("/api/metrics/latest", methods=["GET"])
def latest_metrics():
    """All systems latest — used by admin view."""
    rows = database.get_latest_for_all_systems()
    now = datetime.now(timezone.utc)
    result = []
    for row in rows:
        received_at = row.get("received_at")
        is_online = False
        if received_at:
            received_dt = datetime.strptime(received_at, "%Y-%m-%d %H:%M:%S")
            received_dt = received_dt.replace(tzinfo=timezone.utc)
            is_online = (now - received_dt).total_seconds() <= OFFLINE_THRESHOLD_SECONDS
        row["status"] = "online" if is_online else "offline"
        result.append(row)
    return jsonify(result)


@app.route("/api/metrics/user/<username>", methods=["GET"])
def user_metrics(username):
    """
    Returns the latest reading + history for the system linked to
    this user. This is what the Flutter dashboard calls after login.
    """
    latest = database.get_latest_for_user(username)
    if not latest:
        return jsonify({"error": "No data found for this user. Make sure the agent is running on their PC."}), 404

    now = datetime.now(timezone.utc)
    received_at = latest.get("received_at", "")
    is_online = False
    if received_at:
        received_dt = datetime.strptime(received_at, "%Y-%m-%d %H:%M:%S")
        received_dt = received_dt.replace(tzinfo=timezone.utc)
        is_online = (now - received_dt).total_seconds() <= OFFLINE_THRESHOLD_SECONDS
    latest["status"] = "online" if is_online else "offline"

    history = database.get_history_for_user(username)
    alerts  = database.get_alerts_for_user(username)

    return jsonify({
        "latest":  latest,
        "history": history,
        "alerts":  alerts,
    })


@app.route("/api/metrics/<system_name>", methods=["GET"])
def system_history(system_name):
    limit = request.args.get("limit", DEFAULT_HISTORY_LIMIT, type=int)
    rows = database.get_history(system_name, limit)
    return jsonify(rows)


@app.route("/api/systems", methods=["GET"])
def list_systems():
    return jsonify(database.get_all_system_names())


@app.route("/api/alerts", methods=["POST"])
def receive_alert():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid or missing JSON body"}), 400
    database.insert_alert(data)
    return jsonify({"status": "received"}), 201


@app.route("/api/alerts", methods=["GET"])
def list_alerts():
    limit = request.args.get("limit", 50, type=int)
    return jsonify(database.get_recent_alerts(limit))


if __name__ == "__main__":
    database.init_db()
    print(f"Starting backend server on http://{HOST}:{PORT}")
    app.run(host=HOST, port=PORT, debug=False)

# This runs when deployed on Render (gunicorn calls this directly).
database.init_db()
