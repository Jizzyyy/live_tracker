# 📍 Live Tracker

<div align="center">

[![Download APK](https://img.shields.io/badge/Download-Release%20APK%20(v1.0.0)-00E5FF?style=for-the-badge&logo=android&logoColor=black)](https://github.com/Jizzyyy/live_tracker/releases/latest/download/app-release.apk)
[![GitHub Release](https://img.shields.io/github/v/release/Jizzyyy/live_tracker?color=00E676&style=for-the-badge)](https://github.com/Jizzyyy/live_tracker/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20(Dart%203.x)-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Riverpod%202.x-purple?style=for-the-badge)](https://riverpod.dev)

A high-performance real-time group location sharing and convoy telemetry application built with **Flutter** and **Node.js WebSockets**, featuring an ergonomic **Cyber-Tactical Glassmorphism** design.

</div>

---

## 📥 Quick Download & Installation

You can immediately try and test Live Tracker directly on your Android device without compiling the codebase:

👉 **[Download Latest APK (`v1.0.0`)](https://github.com/Jizzyyy/live_tracker/releases/latest/download/app-release.apk)** (Direct APK download from GitHub Releases)

> **⚠️ Note for Reviewers & Testers (Server Uplink):**
> By default, the application connects to our cloud backend hosted on Render:
> `wss://live-tracker-backend.onrender.com`
> Because Render free instances automatically sleep after 15 minutes of inactivity, the **initial connection test may take ~30–50 seconds to wake up**. Once awake, WebSocket synchronization runs in real time with sub-second latency.

---

## ✨ Core Features & Highlights

### 👥 1. Real-Time Group Convoy Tracking
- **Decentralized Rooms:** Create or join convoy rooms using 6-character alphanumeric codes (`ALPHA1`, `X8G9PQ`).
- **Equal Peer Callsigns:** Every rider has an identity callsign with custom color accents and live battery percentages.
- **Persistent Socket Lifecycle:** Leaving a room returns you to Solo Mode without dropping the WebSocket connection, allowing immediate rejoin or new room creation without reconnect loops.
- **Ghost Member Cleanup:** Authoritative server snapshot synchronization automatically flushes stale members who disconnected while offline.

### 🧭 2. Google Maps-Grade Geodesic Navigation
- **True Course Over Ground (COG):** Real-time heading derived from actual GPS displacement vectors ($\ge 1.5\text{ m}$) using spherical great-circle forward azimuth calculations (`atan2`), rather than erratic magnetic compass sensors.
- **Zero-Speed Heading Retention:** When stopped at traffic lights or resting ($< 1.0\text{ km/h}$), the arrow retains its last forward orientation instead of snapping to North.
- **Shortest Angular Arc Interpolation:** Smooth vehicle rotation prevents $350^\circ$ reverse spins when crossing the North boundary ($0^\circ / 360^\circ$).
- **Upright Icon Layering:** The directional ring and aerodynamic chevron rotate with vehicle movement while the center rider avatar remains upright.

### 🔁 3. Interactive Route Replay & Playback
- **Historical Scrubbing:** Replay saved GPS trips with an interactive timeline scrubber and variable playback speeds ($1\times, 2\times, 5\times, 10\times$).
- **Look-Ahead Vehicle Orientation:** Vehicle marker dynamically angles forward into upcoming road curves with look-ahead distance filters.
- **Auto-Follow Camera:** Toggleable camera tracking that centers the viewport on the vehicle during playback so it never leaves the screen.

### 🛡️ 4. Safety & Convoy Overwatch Watchdogs
- **🚨 Emergency SOS Beacon:** Broadcast instant emergency alerts (Crash, Engine Breakdown, Fuel Empty, Lost) with acoustic siren alerts and device vibrations to all room members.
- **⚠️ Hazard Proximity Watchdog (150m):** Sounds alerts and flashes radar warnings when approaching marked road hazards or potholes.
- **📡 Convoy Separation Alert (500m):** Triggers a warning banner when a rider falls more than 500 meters behind the group.
- **↩️ Inverted Trail Backtracker:** Breadcrumb navigation that inverts your outbound route with cross-track deviation warnings if you stray $> 80\text{ m}$ off-trail.
- **⚡ Tactical Quick Pings:** One-tap broadcast cues for *Hazard*, *Regroup*, *Fuel Stop*, *Turn Left/Right*, and *Rest*.

### 🌐 5. Dual Language System (ID / EN)
- Native reactive support for **Bahasa Indonesia (🇮🇩)** and **English (🇬🇧)**.
- Switch languages on the fly from the Preferences menu without needing an app restart; settings persist via `SharedPreferences`.

### 🔤 6. 100% Inter Typography with Tabular Figures
- High-contrast, clean typography powered entirely by `GoogleFonts.inter`.
- Metrical numbers (speedometer, duration timers, elevation gain/loss, GPS coordinates, split kilometer tables) employ `FontFeature.tabularFigures()` for jitter-free readability during high-speed riding.

### 🗺️ 7. Dynamic Map Styles & Custom Engines
- **Watermark-Free Defaults:** Esri Dark Canvas (high-contrast night basemap), Esri Clean Light, and standard OpenStreetMap.
- **Optional Google Maps Integration:** Input your own Google Maps API Key in Settings to instantly unlock *Roadmap*, *Satellite Hybrid*, and *Terrain* layers.
- **Speed Heatmap Overlay:** Color-coded trajectory polylines displaying speed spectrums across 4 tiers ($< 20$, $20-45$, $45-75$, $> 75\text{ km/h}$).

### 📊 8. Strava-Grade Telemetry & Multi-Format GIS Export
- Comprehensive analytics: distance, moving time, stopped time, average pace, top speed, and elevation profile.
- **One-Tap GIS Export:** Export any completed trip directly to **GPX 1.1** (Strava/Garmin ready), **GeoJSON** (RFC 7946), **KML** (Google Earth), and **CSV**.
- **Social Route Card:** Render and share beautiful glassmorphism summary cards with route minimaps to Instagram/WhatsApp.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter 3.x (Dart 3.x with strict null-safety)
- **State Management:** Riverpod 2.x (`NotifierProvider`, `StreamProvider.autoDispose`, `StateProvider`)
- **Map Rendering:** `flutter_map` 8.3.x + `latlong2`
- **Location & Sensors:** `geolocator` 14.x, `flutter_foreground_task` (Background GPS service)
- **Typography:** `google_fonts` (Inter with `FontFeature.tabularFigures`)
- **Networking:** `web_socket_channel` 3.x (Bi-directional binary/JSON WebSocket client)
- **Backend Server:** Node.js, TypeScript, `ws`

---

## 🚀 Running from Source

If you prefer building from source:

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.27+ recommended)
- Android SDK 21+ (Java 17)

### 2. Clone & Install
```bash
git clone https://github.com/Jizzyyy/live_tracker.git
cd live_tracker
flutter pub get
```

### 3. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 4. Build Release APK
```bash
flutter build apk --release
```
The output binary will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License
Created and maintained by **Kadhafi** ([@Jizzyyy](https://github.com/Jizzyyy)).
Distributed for portfolio demonstration and non-commercial convoy touring use.
