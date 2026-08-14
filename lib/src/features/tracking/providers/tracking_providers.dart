import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/tracking_models.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

// --- Room Session Provider ---
class RoomSessionState {
  const RoomSessionState({
    this.status = TrackingConnectionStatus.disconnected,
    this.roomCode,
    this.userId,
    this.members = const {},
    this.error,
  });

  final TrackingConnectionStatus status;
  final String? roomCode;
  final String? userId;
  final Map<String, MemberLocation> members;
  final String? error;

  RoomSessionState copyWith({
    TrackingConnectionStatus? status,
    String? roomCode,
    String? userId,
    Map<String, MemberLocation>? members,
    String? error,
  }) {
    return RoomSessionState(
      status: status ?? this.status,
      roomCode: roomCode ?? this.roomCode,
      userId: userId ?? this.userId,
      members: members ?? this.members,
      error: error,
    );
  }
}

class RoomSessionNotifier extends Notifier<RoomSessionState> {
  final _ws = WebSocketService();
  StreamSubscription? _sub;

  @override
  RoomSessionState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _ws.dispose();
    });
    return const RoomSessionState();
  }

  void connect(String serverUrl) {
    if (_ws.isConnected) return;
    state = state.copyWith(status: TrackingConnectionStatus.reconnecting);
    _sub?.cancel();
    _ws.connect(serverUrl);
    _sub = _ws.messages.listen(_handleMessage);
  }

  void createRoom() => _ws.send({'type': 'create_room'});
  void joinRoom(String code) => _ws.send({'type': 'join_room', 'roomCode': code.toUpperCase()});
  
  void leaveRoom() {
    _ws.send({'type': 'leave_room'});
    state = state.copyWith(
      status: TrackingConnectionStatus.disconnected,
      roomCode: null,
      members: {},
    );
  }

  void sendPosition(Position pos) {
    if (state.status != TrackingConnectionStatus.connected) return;
    _ws.send({
      'type': 'position_update',
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': pos.speed * 3.6, // m/s to km/h
      'heading': pos.heading,
      'timestamp': pos.timestamp.millisecondsSinceEpoch,
    });
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'connected':
        state = state.copyWith(userId: msg['userId'] as String?);
        if (state.roomCode != null) joinRoom(state.roomCode!);
        break;
      case 'room_created':
      case 'room_joined':
        state = state.copyWith(
          status: TrackingConnectionStatus.connected,
          roomCode: msg['roomCode'] as String?,
          members: {}, // Reset members on new room
        );
        break;
      case 'member_position':
        try {
          final loc = MemberLocation.fromJson(msg);
          state = state.copyWith(
            members: {...state.members, loc.id: loc},
          );
        } catch (e) {
          // Ignore malformed payloads
        }
        break;
      case 'member_left':
        final leftId = msg['userId'] as String?;
        if (leftId != null) {
          final newMembers = Map<String, MemberLocation>.from(state.members)..remove(leftId);
          state = state.copyWith(members: newMembers);
        }
        break;
      case 'error':
        state = state.copyWith(error: msg['message'] as String?);
        break;
    }
  }
}

final roomSessionProvider = NotifierProvider<RoomSessionNotifier, RoomSessionState>(RoomSessionNotifier.new);

// --- Telemetry Provider ---
class TelemetryNotifier extends Notifier<TripTelemetry> {
  final _distanceCalc = const Distance();
  DateTime? _startTime;
  LatLng? _lastPos;

  @override
  TripTelemetry build() {
    // Listen to local GPS stream to calculate live stats
    ref.listen(positionStreamProvider, (prev, next) {
      if (!next.hasValue) return;
      final pos = next.value!;
      if (pos.accuracy > 30.0) return; // Ignore inaccurate jumps
      
      final currentLatLng = LatLng(pos.latitude, pos.longitude);
      _startTime ??= pos.timestamp;
      
      double addedDistance = 0;
      if (_lastPos != null) {
        addedDistance = _distanceCalc.as(LengthUnit.Meter, _lastPos!, currentLatLng);
      }
      _lastPos = currentLatLng;

      final durationSecs = pos.timestamp.difference(_startTime!).inSeconds;
      final totalDist = state.distanceMeters + addedDistance;
      final avgSpeed = durationSecs > 0 ? (totalDist / 1000) / (durationSecs / 3600) : 0.0;

      state = TripTelemetry(
        distanceMeters: totalDist,
        activeDurationSeconds: durationSecs,
        currentSpeedKmh: pos.speed * 3.6,
        avgSpeedKmh: avgSpeed,
      );
    });

    return const TripTelemetry(
      distanceMeters: 0,
      activeDurationSeconds: 0,
      currentSpeedKmh: 0,
      avgSpeedKmh: 0,
    );
  }
}

final telemetryProvider = NotifierProvider<TelemetryNotifier, TripTelemetry>(TelemetryNotifier.new);

// --- Selected Member Provider ---
final selectedMemberProvider = StateProvider<MemberLocation?>((ref) => null);

// Re-export positionStreamProvider locally if needed, assuming it exists in map feature
final positionStreamProvider = StreamProvider.autoDispose<Position>((ref) async* {
  final result = await ensureLocationPermission();
  if (!result.granted) throw Exception(result.message ?? 'Izin lokasi gagal');
  yield* positionStream();
});
