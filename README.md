# Live Tracker

A real-time group location sharing and trip telemetry app built with Flutter & Node.js, featuring a modern Glassmorphism UI.

## Features
- **Real-Time Group Tracking:** Create/join rooms and see live member locations via WebSockets.
- **Trip Telemetry:** Live dashboard for distance, duration, and average speed.
- **Route History:** Save and view past trips locally.
- **Background Service:** Keep tracking when the app is minimized (Android).
- **Dynamic Map Styles:** Switch map tiles instantly.
- **Glassmorphism UI:** Clean, responsive, and modern design.

## Tech Stack
- **Frontend:** Flutter (Riverpod 2.x, flutter_map, geolocator)
- **Backend:** Node.js & WebSockets

## Getting Started

1. **Clone & Install**
   ```bash
   git clone https://github.com/Jizzyyy/live_tracker.git
   cd live_tracker
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Server Uplink**
   When the app launches, you must enter a valid WebSocket server URL (e.g., your Ngrok URL or cloud domain) to access the main map dashboard.

---
Created by kadhafiinl
