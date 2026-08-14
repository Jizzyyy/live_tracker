import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracker_models.dart';
import '../src/core/services/location_service.dart';
import '../src/core/services/websocket_service.dart';

// --- Shared Prefs & Settings ---
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return AppSettings(
      // URL statis yang langsung menunjuk ke cloud
      serverUrl: 'wss://live-tracker-backend.onrender.com',
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      highAccuracyGps: prefs.getBool('highAccuracyGps') ?? true,
      backgroundService: prefs.getBool('backgroundService') ?? true,
    );
  }

  void updateSettings(AppSettings newSettings) {
    state = newSettings;
    final prefs = ref.read(sharedPrefsProvider);
    // Tidak lagi menyimpan serverUrl karena sudah statis
    prefs.setBool('isDarkMode', newSettings.isDarkMode);
    prefs.setBool('highAccuracyGps', newSettings.highAccuracyGps);
    prefs.setBool('backgroundService', newSettings.backgroundService);
  }
}
final appSettingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// --- Map Styles ---
final availableMapStyles = [
  const MapStyleOption(
    id: 'apple_dark',
    name: 'Midnight Dark',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution: 'CartoDB, OSM',
  ),
  const MapStyleOption(
    id: 'apple_light',
    name: 'Clean Light',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    attribution: 'CartoDB, OSM',
  ),
  const MapStyleOption(
    id: 'osm',
    name: 'OSM Standard',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap',
  ),
];
final mapStyleProvider = StateProvider<MapStyleOption>((ref) => availableMapStyles.first);

// --- GPS Location Stream ---
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
  });
  final TrackingConnectionStatus status;
  final String? roomCode;
  final Map<String, MemberLocation> members;

  RoomState copyWith({
    TrackingConnectionStatus? status,
    String? roomCode,
    Map<String, MemberLocation>? members,
  }) => RoomState(
    status: status ?? this.status,
    roomCode: roomCode ?? this.roomCode,
    members: members ?? this.members,
  );
}

class RoomNotifier extends Notifier<RoomState> {
  final _ws = WebSocketService();
  StreamSubscription? _sub;

  @override
  RoomState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _ws.dispose();
    });
    // Auto-connect using static settings URL
    Future.microtask(() => connect());
    return const RoomState();
  }

  void connect() {
    if (_ws.isConnected) return;
    state = state.copyWith(status: TrackingConnectionStatus.reconnecting);
    _ws.connect(ref.read(appSettingsProvider).serverUrl);
    _sub = _ws.messages.listen(_handleMessage);
  }

  void disconnect() {
    _ws.disconnect();
    state = const RoomState();
  }

  void createRoom() => _ws.send({'type': 'create_room'});
  void joinRoom(String code) => _ws.send({'type': 'join_room', 'roomCode': code});
  void leaveRoom() {
    _ws.send({'type': 'leave_room'});
    state = state.copyWith(status: TrackingConnectionStatus.disconnected, roomCode: null, members: {});
  }

  void sendPosition(Position pos) {
    if (state.status != TrackingConnectionStatus.connected) return;
    _ws.send({
      'type': 'position_update',
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': pos.speed,
      'heading': pos.heading,
      'timestamp': pos.timestamp.millisecondsSinceEpoch,
    });
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'connected':
        if (state.roomCode != null) joinRoom(state.roomCode!);
        break;
      case 'room_created':
      case 'room_joined':
        state = state.copyWith(status: TrackingConnectionStatus.connected, roomCode: msg['roomCode']);
        break;
      case 'member_position':
        try {
          final loc = MemberLocation.fromJson(msg);
          state = state.copyWith(members: {...state.members, loc.id: loc});
        } catch (_) {}
        break;
      case 'member_left':
        final leftId = msg['userId'];
        if (leftId != null) {
          final newMembers = Map<String, MemberLocation>.from(state.members)..remove(leftId);
          state = state.copyWith(members: newMembers);
        }
        break;
    }
  }
}
final roomProvider = NotifierProvider<RoomNotifier, RoomState>(RoomNotifier.new);

// --- Trip Session & Route History ---
class TripSessionNotifier extends Notifier<TripSession> {
  final _distanceCalc = const Distance();
  LatLng? _lastPos;
  Timer? _timer;

  @override
  TripSession build() {
    ref.onDispose(() => _timer?.cancel());
    
    // Listen to GPS to calculate distance
    ref.listen(locationStreamProvider, (prev, next) {
      if (state.state != TripSessionState.active || !next.hasValue) return;
      final pos = next.value!;
      if (pos.accuracy > 25.0) return; // Ignore poor accuracy
      
      final currentLatLng = LatLng(pos.latitude, pos.longitude);
      
      double addedDistance = 0;
      if (_lastPos != null) {
        addedDistance = _distanceCalc.as(LengthUnit.Meter, _lastPos!, currentLatLng);
      }
      _lastPos = currentLatLng;

      final totalDist = state.distanceMeters + addedDistance;
      final avgSpeed = state.activeDurationSeconds > 0 ? (totalDist / 1000) / (state.activeDurationSeconds / 3600) : 0.0;

      state = state.copyWith(
        distanceMeters: totalDist,
        currentSpeedKmh: pos.speed * 3.6,
        avgSpeedKmh: avgSpeed,
      );
    });

    return const TripSession();
  }

  void toggleSession() {
    if (state.state == TripSessionState.inactive || state.state == TripSessionState.paused) {
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

  void stopSession() {
    _timer?.cancel();
    _lastPos = null;
    state = const TripSession();
  }
}
final tripSessionProvider = NotifierProvider<TripSessionNotifier, TripSession>(TripSessionNotifier.new);

// --- Focus State ---
final focusedMemberProvider = StateProvider<MemberLocation?>((ref) => null);
