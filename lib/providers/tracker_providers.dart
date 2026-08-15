import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracker_models.dart';
import '../models/trip_history_model.dart';
import '../repositories/trip_history_repository.dart';
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
      serverUrl: prefs.getString('serverUrl') ?? 'ws://192.168.18.13:8080',
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      highAccuracyGps: prefs.getBool('highAccuracyGps') ?? true,
      backgroundService: prefs.getBool('backgroundService') ?? true,
    );
  }
  void updateSettings(AppSettings s) {
    state = s;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString('serverUrl', s.serverUrl);
    prefs.setBool('isDarkMode', s.isDarkMode);
    prefs.setBool('highAccuracyGps', s.highAccuracyGps);
    prefs.setBool('backgroundService', s.backgroundService);
  }
}
final appSettingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// --- Map Styles ---
final availableMapStyles = [
  const MapStyleOption(id: 'dark', name: 'Midnight Dark', urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', attribution: 'CartoDB, OSM'),
  const MapStyleOption(id: 'light', name: 'Clean Light', urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', attribution: 'CartoDB, OSM'),
  const MapStyleOption(id: 'osm', name: 'OSM Standard', urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', attribution: 'OpenStreetMap'),
];
final mapStyleProvider = StateProvider<MapStyleOption>((ref) => availableMapStyles.first);

// --- GPS Stream ---
final locationStreamProvider = StreamProvider.autoDispose<Position>((ref) async* {
  final result = await ensureLocationPermission();
  if (!result.granted) throw Exception(result.message);
  yield* positionStream();
});

// --- Room Session ---
class RoomState {
  const RoomState({this.status = TrackingConnectionStatus.disconnected, this.roomCode, this.members = const {}});
  final TrackingConnectionStatus status;
  final String? roomCode;
  final Map<String, MemberLocation> members;
  RoomState copyWith({TrackingConnectionStatus? status, String? roomCode, Map<String, MemberLocation>? members}) =>
    RoomState(status: status ?? this.status, roomCode: roomCode ?? this.roomCode, members: members ?? this.members);
}

class RoomNotifier extends Notifier<RoomState> {
  final _ws = WebSocketService();
  StreamSubscription? _sub;

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
    _ws.send({'type': 'leave_room'});
    state = state.copyWith(status: TrackingConnectionStatus.disconnected, roomCode: null, members: {});
  }

  void sendPosition(Position pos) {
    if (state.status != TrackingConnectionStatus.connected) return;
    _ws.send({'type': 'position_update', 'lat': pos.latitude, 'lng': pos.longitude, 'speed': pos.speed, 'heading': pos.heading, 'timestamp': pos.timestamp.millisecondsSinceEpoch});
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'connected': if (state.roomCode != null) joinRoom(state.roomCode!); break;
      case 'room_created': case 'room_joined':
        state = state.copyWith(status: TrackingConnectionStatus.connected, roomCode: msg['roomCode']); break;
      case 'member_position':
        try { final loc = MemberLocation.fromJson(msg); state = state.copyWith(members: {...state.members, loc.id: loc}); } catch (_) {} break;
      case 'member_left':
        final id = msg['userId']; if (id != null) state = state.copyWith(members: Map.from(state.members)..remove(id)); break;
    }
  }
}
final roomProvider = NotifierProvider<RoomNotifier, RoomState>(RoomNotifier.new);

// --- Trip Session (with coordinate buffer) ---
class TripSessionNotifier extends Notifier<TripSession> {
  final _distCalc = const Distance();
  LatLng? _lastPos;
  Timer? _timer;
  DateTime? _startTime;
  double _maxSpeed = 0;
  final List<RoutePoint> _routeBuffer = [];

  @override
  TripSession build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(locationStreamProvider, (prev, next) {
      if (state.state != TripSessionState.active || !next.hasValue) return;
      final pos = next.value!;
      if (pos.accuracy > 25.0) return;
      
      final ll = LatLng(pos.latitude, pos.longitude);
      double added = 0;
      if (_lastPos != null) added = _distCalc.as(LengthUnit.Meter, _lastPos!, ll);
      _lastPos = ll;

      // Record breadcrumb
      _routeBuffer.add(RoutePoint(
        latitude: pos.latitude, longitude: pos.longitude,
        timestamp: pos.timestamp.millisecondsSinceEpoch,
        speed: pos.speed * 3.6, altitude: pos.altitude,
      ));

      final speedKmh = pos.speed * 3.6;
      if (speedKmh > _maxSpeed) _maxSpeed = speedKmh;

      final totalDist = state.distanceMeters + added;
      final avgSpeed = state.activeDurationSeconds > 0 ? (totalDist / 1000) / (state.activeDurationSeconds / 3600) : 0.0;

      state = state.copyWith(distanceMeters: totalDist, currentSpeedKmh: speedKmh, avgSpeedKmh: avgSpeed);
    });
    return const TripSession();
  }

  void toggleSession() {
    if (state.state == TripSessionState.inactive || state.state == TripSessionState.paused) {
      _startTime ??= DateTime.now();
      state = state.copyWith(state: TripSessionState.active);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.state == TripSessionState.active) {
          state = state.copyWith(activeDurationSeconds: state.activeDurationSeconds + 1);
        }
      });
    } else {
      _lastPos = null;
      state = state.copyWith(state: TripSessionState.paused, currentSpeedKmh: 0);
      _timer?.cancel();
    }
  }

  /// CRITICAL FIX: async stop that awaits persistence before resetting state
  Future<void> stopSession(BuildContext context) async {
    _timer?.cancel();

    // Guard: discard meaningless trips
    if (_routeBuffer.length < 2 || state.distanceMeters < 10) {
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip too short to save.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final trip = CompletedTrip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      durationSeconds: state.activeDurationSeconds,
      distanceMeters: state.distanceMeters,
      avgSpeedKmh: state.avgSpeedKmh,
      maxSpeedKmh: _maxSpeed,
      routePoints: List.unmodifiable(_routeBuffer),
    );

    // AWAIT persistence before resetting state
    final saved = await ref.read(tripHistoryProvider.notifier).saveTrip(trip);

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip saved!'), behavior: SnackBarBehavior.floating),
      );
    }

    _reset();
  }

  void _reset() {
    _lastPos = null;
    _startTime = null;
    _maxSpeed = 0;
    _routeBuffer.clear();
    state = const TripSession();
  }
}
final tripSessionProvider = NotifierProvider<TripSessionNotifier, TripSession>(TripSessionNotifier.new);

// --- Trip History Provider (backed by repository) ---
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
