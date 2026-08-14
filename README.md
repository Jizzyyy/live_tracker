# 📍 Live Tracker (Premium Cyber-Tactical)

A high-performance, real-time group location sharing and trip telemetry application built with Flutter & Node.js. 
Inspired by the UX of Apple Fitness and Zenly, featuring a modern **Cyber-Tactical Glassmorphism** design.

---

## ✨ Features

- **Real-Time Group Tracking:** Create or join private rooms. Broadcast and view all members' live locations on the map instantly via WebSockets.
- **Trip Telemetry Engine:** Live dashboard calculating distance (km), active duration, and average speed. Intelligent filtering ignores inaccurate GPS spikes.
- **Route History (Local Logging):** Saves completed trips locally using `SharedPreferences` with a sleek History viewer.
- **Background Location Service:** Keeps tracking your route even when the app is minimized or the screen is locked (Android Foreground Service).
- **Dynamic Map Styles:** Switch between *Midnight Dark, Clean Light, and OSM Standard* instantly without rebuilding the map tree.
- **Premium Glassmorphism UI:** Built with custom BackdropFilters, responsive Auto-Centering, dynamic Compass, and strict `FontFeature.tabularFigures()` to prevent text jitter on live telemetry updates.

## 🛠 Tech Stack

**Mobile Client (This Repository):**
- **Framework:** Flutter 3.x (Strict Null Safety)
- **State Management:** Riverpod 2.x (NotifierProvider, StreamProvider)
- **Map Engine:** `flutter_map` + `latlong2`
- **Location:** `geolocator`
- **Typography:** `google_fonts` (JetBrains Mono & Share Tech Mono)

**Backend Server:**
- **Environment:** Node.js + TypeScript
- **Protocol:** Raw WebSockets (`ws` library)

---

## 🚀 Getting Started

Because this app relies on a real-time WebSocket connection to sync locations, you need a running backend server.

### 1. Setup the Backend Server
You must have the backend server running either locally, via Ngrok, or hosted on a cloud provider like Render/Railway.
*(Note: The server repository is maintained privately by the author. If you are cloning this, you must write your own basic WebSocket server that handles `create_room`, `join_room`, and `position_update` payloads).*

### 2. Setup the Flutter Client
Clone this repository and run the standard Flutter setup:
```bash
git clone https://github.com/Jizzyyy/live_tracker.git
cd live_tracker
flutter pub get
flutter run
```

### 3. The "Server Uplink" Gateway
When you launch the app, you will be greeted by the **Server Uplink** screen. 
You **must** input a valid WebSocket URL to proceed to the map.

* **If using Ngrok (Local Testing):**
  Run your server, expose it via `ngrok http 8080`, and enter the wss link.
  *Example:* `wss://abcd-1234.ngrok-free.app`
* **If hosted on Cloud (Production):**
  Enter your cloud WebSocket domain.
  *Example:* `wss://your-tracker-backend.onrender.com`

---

## 🏗 Architecture Blueprint

This app transitioned from a feature-first pattern to a highly decoupled Domain-Driven UI pattern:
- `lib/models/`: Strongly typed, immutable data models with JSON serialization.
- `lib/providers/`: Riverpod 2.x state controllers managing WebSockets, GPS streams, and Trip calculators.
- `lib/widgets/`: Modular UI components wrapped in `RepaintBoundary` for 60FPS marker animations and heavy telemetry updates.
- `lib/screens/`: Orchestration layers combining the Map Canvas, Floating Docks, and Glassmorphism headers.

---

## ⚖️ License & Copyright

**Forged by KadhafiINL**

This project is provided for educational and portfolio demonstration purposes. 
*Copyright © 2026 Kadhafi. All Rights Reserved.* 
You may view and study this code, but commercial reproduction, redistribution, or publishing of this application without explicit permission is strictly prohibited.
