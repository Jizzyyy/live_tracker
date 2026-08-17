# 📍 Live Tracker

A real-time group location sharing and trip telemetry app built with Flutter & Node.js, featuring a modern Glassmorphism UI.

## ✨ Features
- 👥 **Real-Time Group Tracking:** Create/join rooms and see live member locations via WebSockets.
- 📊 **Trip Telemetry:** Live dashboard for distance, duration, and average speed.
- 🗺️ **Route History & GPX Export:** Save and view past trips locally with one-tap GPX 1.1 file export for Strava/Garmin.
- 🔋 **Background Service:** Keep tracking when the app is minimized (Android).
- 🎨 **Dynamic Map Styles:** Switch map tiles instantly.
- 🪟 **Glassmorphism UI:** Clean, responsive, and modern design.

## 🛠️ Tech Stack
- **Frontend:** Flutter (Riverpod 2.x, flutter_map, geolocator)
- **Backend:** Node.js & WebSockets

## 🚀 Getting Started

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

3. **🔌 Server Uplink Setup**
   Because this app relies on WebSockets for real-time synchronization, you will be greeted by a **"Server Uplink"** screen upon opening the app. You must input a valid WebSocket URL to proceed:

   - **Local Testing (Ngrok):**
     If you are running your own local Node.js WebSocket server, expose it to the internet using Ngrok (e.g., `ngrok http 8080`). 
     Copy the generated forwarding URL, change `https://` to `wss://`, and paste it into the app.
     *Example:* `wss://abcd-1234.ngrok-free.app`

   - **Cloud Production:**
     If your server is deployed online (e.g., Render, Railway), simply input your domain with the `wss://` protocol.
     *Example:* `wss://your-tracker-backend.onrender.com`

---
Created by kadhafiinl
