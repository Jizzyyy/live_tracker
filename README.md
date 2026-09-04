# 📍 Live Tracker

A real-time group location sharing and trip telemetry app built with Flutter & Node.js, featuring a modern Glassmorphism UI.

## ✨ Features
- 👥 **Real-Time Group Tracking:** Create/join rooms and see live member locations via WebSockets.
- 📊 **Trip Telemetry:** Live dashboard for distance, duration, and average speed.
- 🗺️ **Route History & GPX Export:** Save and view past trips locally with one-tap GPX 1.1 file export for Strava/Garmin.
- 🔋 **Background Service:** Keep tracking when the app is minimized (Android).
- 🎨 **Dynamic Map Styles & Engines:** Switch between OpenStreetMap (OSM Standard, CartoDB Dark/Light) and Google Maps (Roadmap, Satellite Hybrid, Terrain).
- 🪟 **Glassmorphism UI:** Clean, responsive, and modern design.

## 🗺️ Map Providers & Guide (OSM vs Google Maps)

Live Tracker mendukung multi-provider map tiles:

### 1. OpenStreetMap (OSM) & CartoDB (Default / Free)
Secara default, aplikasi langsung siap pakai **tanpa API Key** menggunakan:
- **Midnight Dark**: CartoDB Dark basemap (hemat baterai & kontras tinggi).
- **Clean Light**: CartoDB Light basemap.
- **OSM Standard**: OpenStreetMap standard global tiles.

### 2. Google Maps Tiles (Roadmap, Satellite Hybrid, Terrain)
Aplikasi mendukung rendering Google Maps tiles langsung di viewport. Karena alasan keamanan privasi & kuota, **API Key tidak di-hardcode ke repo publik**.

**Cara Mengaktifkan Google Maps:**
1. Buka menu **Preferences / Settings (Ikon Gear)** di dalam aplikasi.
2. Di bagian **"Google Maps API Key (Opsional)"**, masukkan API Key Google Maps Anda (misal: `AIzaSy...` atau key Map Tiles API Anda).
3. Tekan tombol checklist/simpan.
4. Buka menu **Map Style (Ikon Layer)** di sudut kanan atas layar utama. Pilihan berikut akan otomatis muncul dan aktif:
   - **Google Maps (Roadmap)**
   - **Google Maps (Satellite Hybrid)**
   - **Google Maps (Terrain)**
5. Jika API Key dikosongkan, pilihan map akan kembali ke mode default OpenStreetMap / CartoDB.

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
