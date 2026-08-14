# Live Tracker

Real-time location sharing app built with Flutter.

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Maps:** OpenStreetMap via `flutter_map`
- **GPS:** Geolocator
- **Architecture:** Feature-first

## Getting Started

```bash
flutter pub get
flutter run
```

## Roadmap

- [x] Map rendering (OSM)
- [x] Custom Material 3 theme
- [x] Splash screen
- [x] GPS location tracking
- [x] Live position marker
- [x] Auto-center on first fix
- [x] Real-time position sharing (WebSocket)
- [x] Group tracking
- [x] Route polyline
- [x] Background location service (foreground notification)
- [x] Map style switcher (multiple tile sources)
- [x] Trip statistics (distance, duration, speed)
- [x] Map UX controls (compass, scale bar)
- [ ] Route replay / history export

## Architecture

This project uses a feature-first architecture:
- `features/map`: Rendering, GPS, and stats
- `features/room`: WebSocket connections and multi-user sync
- `features/settings`: Persisted configurations

State management powered by **Riverpod** with strict separation of `StateNotifierProviders` for routes, positions, and connections.

