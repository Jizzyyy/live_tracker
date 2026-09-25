import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/tracker_models.dart';
import '../models/trip_history_model.dart';
import '../repositories/trip_history_repository.dart';
import '../services/background_tracking_service.dart';
import '../src/core/services/location_service.dart';
import '../src/core/services/websocket_service.dart';

// --- Shared Prefs ---
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

// --- Settings ---
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return AppSettings(
      serverUrl: prefs.getString('serverUrl') ?? 'wss://live-tracker-backend.onrender.com',
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      highAccuracyGps: prefs.getBool('highAccuracyGps') ?? true,
      backgroundService: prefs.getBool('backgroundService') ?? true,
      googleMapsApiKey: prefs.getString('googleMapsApiKey') ?? '',
      cartoApiKey: prefs.getString('cartoApiKey') ?? '',
    );
  }
  void updateSettings(AppSettings s) {
    state = s;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString('serverUrl', s.serverUrl);
    prefs.setBool('isDarkMode', s.isDarkMode);
    prefs.setBool('highAccuracyGps', s.highAccuracyGps);
    prefs.setBool('backgroundService', s.backgroundService);
    prefs.setString('googleMapsApiKey', s.googleMapsApiKey);
    prefs.setString('cartoApiKey', s.cartoApiKey);
  }
}
final appSettingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// --- Map Styles ---
List<MapStyleOption> getAvailableMapStyles([String googleApiKey = '', String cartoApiKey = '']) {
  final styles = <MapStyleOption>[
    // 1. Default Watermark-Free Esri Dark Canvas
    const MapStyleOption(
      id: 'dark',
      name: 'Midnight Dark (Esri Canvas)',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      attribution: 'Esri, HERE, Garmin, OpenStreetMap',
    ),
    // 2. OpenStreetMap Standard
    const MapStyleOption(
      id: 'osm',
      name: 'OSM Standard (OpenStreetMap)',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: [],
      attribution: 'OpenStreetMap contributors',
    ),
    // 3. Clean Light Esri Canvas
    const MapStyleOption(
      id: 'light',
      name: 'Clean Light (Esri Canvas)',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      attribution: 'Esri, HERE, Garmin, OpenStreetMap',
    ),
    // 4. Free Satellite Aerial Imagery
    const MapStyleOption(
      id: 'satellite',
      name: 'Satellite Aerial (Esri Imagery)',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      attribution: 'Esri, Maxar, Earthstar Geographics',
    ),
  ];

  // Optional: CartoDB Basemaps if API key is provided or explicit request
  if (cartoApiKey.trim().isNotEmpty) {
    final keyParam = '?key=${cartoApiKey.trim()}';
    styles.addAll([
      MapStyleOption(
        id: 'carto_dark',
        name: 'CartoDB Dark Matter (Auth)',
        urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png$keyParam',
        subdomains: const ['a', 'b', 'c', 'd'],
        attribution: 'CARTO, OpenStreetMap',
      ),
      MapStyleOption(
        id: 'carto_light',
        name: 'CartoDB Positron (Auth)',
        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png$keyParam',
        subdomains: const ['a', 'b', 'c', 'd'],
        attribution: 'CARTO, OpenStreetMap',
      ),
    ]);
  }

  // Optional: Google Maps if API key is provided
  if (googleApiKey.trim().isNotEmpty) {
    styles.addAll([
      MapStyleOption(
        id: 'google_roadmap',
        name: 'Google Maps (Roadmap)',
        urlTemplate: 'https://mt0.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=$googleApiKey',
        subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
        attribution: 'Google Maps',
      ),
      MapStyleOption(
        id: 'google_satellite',
        name: 'Google Maps (Satellite Hybrid)',
        urlTemplate: 'https://mt0.google.com/vt/lyrs=y&x={x}&y={y}&z={z}&key=$googleApiKey',
        subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
        attribution: 'Google Maps',
      ),
      MapStyleOption(
        id: 'google_terrain',
        name: 'Google Maps (Terrain)',
        urlTemplate: 'https://mt0.google.com/vt/lyrs=p&x={x}&y={y}&z={z}&key=$googleApiKey',
        subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
        attribution: 'Google Maps',
      ),
    ]);
  }

  return styles;
}

final availableMapStyles = getAvailableMapStyles();
final mapStyleListProvider = Provider<List<MapStyleOption>>((ref) {
  final googleKey = ref.watch(appSettingsProvider.select((s) => s.googleMapsApiKey));
  final cartoKey = ref.watch(appSettingsProvider.select((s) => s.cartoApiKey));
  return getAvailableMapStyles(googleKey, cartoKey);
});

final mapStyleProvider = StateProvider<MapStyleOption>((ref) => getAvailableMapStyles().first);

// --- GPS Stream (Throttled via distanceFilter) ---
final locationStreamProvider = StreamProvider.autoDispose<Position>((ref) async* {
  final result = await ensureLocationPermission();
  if (!result.granted) throw Exception(result.message);
  yield* positionStream();
});

// --- Room Session ---
class RoomState {
  const RoomState({
    this.status = TrackingConnectionStatus.disconnected,
    this.roomCode,
    this.members = const {},
    this.activeSos,
    this.pois = const {},
  });

  final TrackingConnectionStatus status;
  final String? roomCode;
  final Map<String, MemberLocation> members;
  final SosAlert? activeSos;
  final Map<String, SharedPoi> pois;

  RoomState copyWith({
    TrackingConnectionStatus? status,
    String? roomCode,
    Map<String, MemberLocation>? members,
    SosAlert? Function()? activeSos,
    Map<String, SharedPoi>? pois,
  }) =>
    RoomState(
      status: status ?? this.status,
      roomCode: roomCode ?? this.roomCode,
      members: members ?? this.members,
      activeSos: activeSos != null ? activeSos() : this.activeSos,
      pois: pois ?? this.pois,
    );
}

class RoomNotifier extends Notifier<RoomState> {
  final _ws = WebSocketService();
  StreamSubscription? _sub;
  int _lastWsSendMs = 0;

  @override
  RoomState build() {
    ref.onDispose(() { _sub?.cancel(); _ws.dispose(); });
    Future.microtask(() => connect());
    return const RoomState();
  }

  void connect() {
    if (_ws.isConnected) return;
    state = state.copyWith(status: TrackingConnectionStatus.reconnecting);
    _ws.connect(ref.read(appSettingsProvider).serverUrl);
    _sub = _ws.messages.listen(_handleMessage);
  }

  void reconnect() {
    if (state.status == TrackingConnectionStatus.connected && state.roomCode != null) leaveRoom();
    _sub?.cancel(); _ws.disconnect();
    state = const RoomState(status: TrackingConnectionStatus.reconnecting);
    _ws.connect(ref.read(appSettingsProvider).serverUrl);
    _sub = _ws.messages.listen(_handleMessage);
  }

  void disconnect() { _ws.disconnect(); state = const RoomState(); }
  void createRoom() => _ws.send({'type': 'create_room'});
  void joinRoom(String code) => _ws.send({'type': 'join_room', 'roomCode': code});
  void leaveRoom() {
    // 1. Send leave event to server
    _ws.send({'type': 'leave_room'});
    
    // 2. Disconnect WebSocket cleanly to prevent automated ping/pong reconnects
    _ws.disconnect();
    _sub?.cancel();
    _sub = null;

    // 3. Reset state permanently to disconnected
    state = const RoomState(
      status: TrackingConnectionStatus.disconnected,
      roomCode: null,
      members: {},
      activeSos: null,
      pois: {},
    );
  }

  /// Broadcast Emergency SOS to all members in current room
  void sendSosAlert(String note, {double? lat, double? lng}) {
    if (state.status != TrackingConnectionStatus.connected) return;
    final alert = SosAlert(
      userId: 'ME',
      note: note,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(activeSos: () => alert);
    _ws.send({
      'type': 'sos_alert',
      'note': note,
      'lat': lat,
      'lng': lng,
    });
  }

  /// Dismiss active SOS alert
  void dismissSos() {
    state = state.copyWith(activeSos: () => null);
    if (state.status == TrackingConnectionStatus.connected) {
      _ws.send({'type': 'sos_dismiss'});
    }
  }

  /// Create and broadcast a shared tactical POI
  void createPoi(SharedPoi poi) {
    state = state.copyWith(pois: {...state.pois, poi.id: poi});
    if (state.status == TrackingConnectionStatus.connected) {
      _ws.send({
        'type': 'poi_create',
        'poi': poi.toJson(),
      });
    }
  }

  /// Delete and broadcast deletion of a shared tactical POI
  void deletePoi(String poiId) {
    final updated = Map<String, SharedPoi>.from(state.pois)..remove(poiId);
    state = state.copyWith(pois: updated);
    if (state.status == TrackingConnectionStatus.connected) {
      _ws.send({
        'type': 'poi_delete',
        'poiId': poiId,
      });
    }
  }

  /// Throttled WS Broadcast to max 1 Hz (1000ms) to reduce battery/bandwidth
  void sendPosition(Position pos, {int? batteryPercent}) {
    if (state.status != TrackingConnectionStatus.connected) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastWsSendMs < 1000) return;
    _lastWsSendMs = now;

    _ws.send({
      'type': 'position_update',
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': pos.speed * 3.6, // send km/h
      'heading': pos.heading,
      'battery': batteryPercent,
      'timestamp': pos.timestamp.millisecondsSinceEpoch,
    });
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'connected':
        state = state.copyWith(status: TrackingConnectionStatus.connected);
        if (state.roomCode != null) joinRoom(state.roomCode!);
        break;
      case 'room_created': case 'room_joined':
        state = state.copyWith(status: TrackingConnectionStatus.connected, roomCode: msg['roomCode']); break;
      case 'member_position':
        try { final loc = MemberLocation.fromJson(msg); state = state.copyWith(members: {...state.members, loc.id: loc}); } catch (_) {} break;
      case 'member_left':
        final id = msg['userId']; if (id != null) state = state.copyWith(members: Map.from(state.members)..remove(id)); break;
      case 'sos_alert':
        try {
          final alert = SosAlert.fromJson(msg);
          state = state.copyWith(activeSos: () => alert);
        } catch (_) {}
        break;
      case 'sos_dismiss':
        state = state.copyWith(activeSos: () => null);
        break;
      case 'poi_created':
        try {
          if (msg['poi'] != null) {
            final poi = SharedPoi.fromJson(msg['poi'] as Map<String, dynamic>);
            state = state.copyWith(pois: {...state.pois, poi.id: poi});
          }
        } catch (_) {}
        break;
      case 'poi_deleted':
        final pId = msg['poiId'] as String?;
        if (pId != null) {
          final updated = Map<String, SharedPoi>.from(state.pois)..remove(pId);
          state = state.copyWith(pois: updated);
        }
        break;
    }
  }
}
final roomProvider = NotifierProvider<RoomNotifier, RoomState>(RoomNotifier.new);

// --- Convoy Separation Watchdog (500m Safe Radius) ---
@immutable
class ConvoySeparationState {
  final bool isSeparated;
  final double distanceMeters;
  final String? memberId;

  const ConvoySeparationState({
    this.isSeparated = false,
    this.distanceMeters = 0.0,
    this.memberId,
  });
}

final convoySeparationProvider = Provider<ConvoySeparationState>((ref) {
  final posAsync = ref.watch(locationStreamProvider);
  final members = ref.watch(roomProvider.select((r) => r.members.values.toList()));
  
  if (!posAsync.hasValue || members.isEmpty) {
    return const ConvoySeparationState();
  }

  final pos = posAsync.value!;
  final myLatLng = LatLng(pos.latitude, pos.longitude);
  const distCalc = Distance();

  double minDistance = double.infinity;
  String? nearestMemberId;

  for (final m in members) {
    final d = distCalc.as(LengthUnit.Meter, myLatLng, LatLng(m.latitude, m.longitude));
    if (d < minDistance) {
      minDistance = d;
      nearestMemberId = m.id;
    }
  }

  final isSeparated = minDistance.isFinite && minDistance > 500.0;
  return ConvoySeparationState(
    isSeparated: isSeparated,
    distanceMeters: minDistance.isFinite ? minDistance : 0.0,
    memberId: nearestMemberId,
  );
});

// --- Auto-Follow Camera State ---
final autoFollowProvider = StateProvider<bool>((ref) => true);

// --- Telemetry Dock Expansion State ---
final telemetryExpandedProvider = StateProvider<bool>((ref) => false);

// --- Trip Session (Optimized with displacement filter & downsampling) ---
class TripSessionNotifier extends Notifier<TripSession> {
  final _distCalc = const Distance();
  LatLng? _lastPos;
  Timer? _timer;
  DateTime? _startTime;
  double _maxSpeed = 0;
  final List<RoutePoint> _routeBuffer = [];
  final List<LatLng> _simplifiedCache = [];
  int _lastUiEmitMs = 0;

  List<RoutePoint> get routeBuffer => List.unmodifiable(_routeBuffer);
  List<LatLng> get simplifiedRoute => List.unmodifiable(_simplifiedCache);

  @override
  TripSession build() {
    ref.onDispose(() {
      _timer?.cancel();
      FlutterForegroundTask.removeTaskDataCallback(_onForegroundData);
    });

    FlutterForegroundTask.addTaskDataCallback(_onForegroundData);

    // Listen to main locationStreamProvider ONLY when background task is not running
    ref.listen(locationStreamProvider, (prev, next) {
      if (state.state != TripSessionState.active || !next.hasValue) return;
      // Skip duplicate processing if background service is actively supplying data
      final isBgActive = ref.read(appSettingsProvider).backgroundService;
      if (isBgActive) return;

      final pos = next.value!;
      _processPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedMps: pos.speed,
        heading: pos.heading,
        altitude: pos.altitude,
        accuracy: pos.accuracy,
        timestampMs: pos.timestamp.millisecondsSinceEpoch,
      );
    });

    return const TripSession();
  }

  void _onForegroundData(Object data) {
    if (data is Map<String, dynamic>) {
      if (data['action'] == 'stop_session') {
        stopSession();
      } else if (data.containsKey('lat') && data.containsKey('lng')) {
        _processPosition(
          latitude: (data['lat'] as num).toDouble(),
          longitude: (data['lng'] as num).toDouble(),
          speedMps: (data['speed'] as num?)?.toDouble() ?? 0.0,
          heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
          altitude: (data['altitude'] as num?)?.toDouble(),
          accuracy: (data['accuracy'] as num?)?.toDouble() ?? 10.0,
          timestampMs: data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
    }
  }

  void _processPosition({
    required double latitude,
    required double longitude,
    required double speedMps,
    required double heading,
    double? altitude,
    required double accuracy,
    required int timestampMs,
  }) {
    if (state.state != TripSessionState.active) return;
    if (accuracy > 25.0) return;

    final currentLatLng = LatLng(latitude, longitude);
    double addedDist = 0;
    if (_lastPos != null) {
      addedDist = _distCalc.as(LengthUnit.Meter, _lastPos!, currentLatLng);
      // Filter out micro jitter (< 2.0 meters) to avoid polyline bloating
      if (addedDist < 2.0) return;
    }
    _lastPos = currentLatLng;

    _routeBuffer.add(RoutePoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestampMs,
      speed: speedMps * 3.6,
      altitude: altitude,
    ));

    // Cap route buffer to max 1000 points to prevent memory leaks on multi-hour trips
    if (_routeBuffer.length > 1000) {
      _routeBuffer.removeAt(0);
    }

    // Dynamic downsampling: incremental push to simplified cache O(1) instead of re-filtering full list O(N)
    _simplifiedCache.add(currentLatLng);
    if (_simplifiedCache.length > 500) {
      _simplifiedCache.removeAt(0);
    }

    final speedKmh = speedMps * 3.6;
    if (speedKmh > _maxSpeed) _maxSpeed = speedKmh;

    final totalDist = state.distanceMeters + addedDist;
    final avgSpeed = state.activeDurationSeconds > 0
        ? (totalDist / 1000) / (state.activeDurationSeconds / 3600)
        : 0.0;

    // Throttle state update to at most once per 500ms to preserve 60/120 FPS
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUiEmitMs >= 500 || state.distanceMeters == 0) {
      _lastUiEmitMs = now;
      state = state.copyWith(
        distanceMeters: totalDist,
        currentSpeedKmh: speedKmh,
        avgSpeedKmh: avgSpeed,
      );

      BackgroundTrackingManager.updateNotificationData(
        distance: state.formattedDistance,
        duration: state.formattedDuration,
      );
    }
  }

  void toggleSession() async {
    if (state.state == TripSessionState.inactive || state.state == TripSessionState.paused) {
      _startTime ??= DateTime.now();
      state = state.copyWith(state: TripSessionState.active);

      final backgroundEnabled = ref.read(appSettingsProvider).backgroundService;
      if (backgroundEnabled) {
        await BackgroundTrackingManager.startService();
      }

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.state == TripSessionState.active) {
          state = state.copyWith(activeDurationSeconds: state.activeDurationSeconds + 1);
          BackgroundTrackingManager.updateNotificationData(
            distance: state.formattedDistance,
            duration: state.formattedDuration,
          );
        }
      });
    } else {
      _lastPos = null;
      state = state.copyWith(state: TripSessionState.paused, currentSpeedKmh: 0);
      _timer?.cancel();
    }
  }

  Future<bool> stopSession() async {
    _timer?.cancel();
    await BackgroundTrackingManager.stopService();

    if (_routeBuffer.length < 2 || state.distanceMeters < 10) {
      _reset();
      return false;
    }

    final now = DateTime.now();
    final randomSuffix = (now.microsecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    final trip = CompletedTrip(
      id: '${now.millisecondsSinceEpoch}_$randomSuffix',
      startTime: _startTime ?? now,
      endTime: now,
      durationSeconds: state.activeDurationSeconds,
      distanceMeters: state.distanceMeters,
      avgSpeedKmh: state.avgSpeedKmh,
      maxSpeedKmh: _maxSpeed,
      routePoints: List.unmodifiable(_routeBuffer),
    );

    final saved = await ref.read(tripHistoryProvider.notifier).saveTrip(trip);
    _reset();
    return saved;
  }

  void _reset() {
    _lastPos = null;
    _startTime = null;
    _maxSpeed = 0;
    _routeBuffer.clear();
    _simplifiedCache.clear();
    state = const TripSession();
  }
}
final tripSessionProvider = NotifierProvider<TripSessionNotifier, TripSession>(TripSessionNotifier.new);

// --- Trip History Provider ---
class TripHistoryNotifier extends Notifier<List<CompletedTrip>> {
  late final TripHistoryRepository _repo;

  @override
  List<CompletedTrip> build() {
    _repo = TripHistoryRepository(ref.read(sharedPrefsProvider));
    return _repo.loadAll();
  }

  Future<bool> saveTrip(CompletedTrip trip) async {
    final ok = await _repo.save(trip);
    if (ok) state = [trip, ...state];
    return ok;
  }

  Future<void> deleteTrip(String id) async {
    await _repo.delete(id);
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }
}
final tripHistoryProvider = NotifierProvider<TripHistoryNotifier, List<CompletedTrip>>(TripHistoryNotifier.new);

// --- Focus State ---
final focusedMemberProvider = StateProvider<MemberLocation?>((ref) => null);
