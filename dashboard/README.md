# Monitoring Dashboard (Flutter)

A real-time dashboard showing CPU, RAM, Disk, and Network usage for every
monitored PC, built against the backend API from Member 2.

## Setup

1. Make sure the Flutter SDK is installed:
   ```
   flutter doctor
   ```
   Fix anything marked with an X (you can usually ignore Android
   toolchain warnings if you plan to run this as a web app).

2. From this `dashboard/` folder, install dependencies:
   ```
   flutter pub get
   ```

3. **Important:** open `lib/config.dart` and change `baseUrl` to point
   at Member 2's backend server, e.g.:
   ```dart
   static const String baseUrl = 'http://192.168.1.105:5000';
   ```
   Find that PC's IP address with `ipconfig` (Windows) — look for the
   "IPv4 Address" line. Both PCs must be on the same Wi-Fi network.

4. Run the app:
   ```
   flutter run -d chrome
   ```
   (Running on Chrome avoids needing an Android emulator. The app also
   runs fine on a physical Android device or emulator if preferred.)

## What it does

- **Dashboard screen**: a grid of cards, one per PC that has reported
  data, showing online/offline status, OS, IP, and live CPU/RAM/Disk
  usage bars (color-coded green/amber/red by threshold) plus current
  network throughput.
- **Detail screen**: tap any card to see line charts of that PC's
  recent CPU, RAM, Disk, and Network history.
- Both screens auto-refresh every 5 seconds (matches the agent's send
  interval — change `refreshInterval` in `lib/config.dart` if needed).

## Troubleshooting

- **"Cannot reach the backend"**: check that `app.py` (Member 2) is
  running, that `baseUrl` in `lib/config.dart` is correct, and that
  both machines are on the same network. Test the backend directly by
  opening `http://<ip>:5000/` in a browser — you should see a small
  JSON status message.
- **No systems showing**: make sure at least one monitoring agent
  (Member 1) is running and pointed at the same backend.
- **CORS errors (web only)**: the backend already sends permissive
  CORS headers, so this shouldn't occur. If it does, confirm you're
  running the latest `app.py`.
