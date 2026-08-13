import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/websocket_service.dart';

import 'member_positions_provider.dart';
import 'member_routes_provider.dart';

enum RoomStatus { disconnected, connecting, inRoom }

class RoomState {
  const RoomState({
    this.status = RoomStatus.disconnected,
    this.roomCode,
    this.userId,
    this.members = const [],
    this.error,
  });

  final RoomStatus status;
  final String? roomCode;
  final String? userId;
  final List<String> members;
  final String? error;

  RoomState copyWith({
    RoomStatus? status,
    String? roomCode,
    String? userId,
    List<String>? members,
    String? error,
  }) {
    return RoomState(
      status: status ?? this.status,
      roomCode: roomCode ?? this.roomCode,
      userId: userId ?? this.userId,
      members: members ?? this.members,
      error: error,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  RoomNotifier(this.ref) : super(const RoomState());

  final Ref ref;
  final _ws = WebSocketService();
  StreamSubscription? _sub;

  void connect(String serverUrl) {
    // Guard: don't reconnect if already connected
    if (_ws.isConnected) return;

    state = state.copyWith(status: RoomStatus.connecting);
    _sub?.cancel();
    _ws.connect(serverUrl);
    _sub = _ws.messages.listen(_handleMessage);
  }

  void createRoom() {
    _ws.send({'type': 'create_room'});
  }

  void joinRoom(String code) {
    _ws.send({'type': 'join_room', 'roomCode': code.toUpperCase()});
  }

  void leaveRoom() {
    _ws.send({'type': 'leave_room'});
    ref.read(memberPositionsProvider.notifier).clear();
    ref.read(memberRoutesProvider.notifier).clear();
    state = state.copyWith(
      status: RoomStatus.disconnected,
      roomCode: null,
      members: [],
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void sendPosition(double lat, double lng) {
    if (state.status != RoomStatus.inRoom) return;
    _ws.send({'type': 'position_update', 'lat': lat, 'lng': lng});
  }

  void reconnect(String serverUrl) {
    if (state.status == RoomStatus.inRoom) leaveRoom();
    _sub?.cancel();
    _ws.disconnect();
    state = state.copyWith(status: RoomStatus.connecting);
    _ws.connect(serverUrl);
    _sub = _ws.messages.listen(_handleMessage);
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'connected':
        state = state.copyWith(userId: msg['userId'] as String?);
        break;

      case 'room_created':
      case 'room_joined':
        state = state.copyWith(
          status: RoomStatus.inRoom,
          roomCode: msg['roomCode'] as String?,
          members: List<String>.from(msg['members'] ?? []),
        );
        break;

      case 'member_joined':
        state = state.copyWith(
          members: List<String>.from(msg['members'] ?? []),
        );
        break;

      case 'member_left':
        final leftId = msg['userId'] as String?;
        if (leftId != null) {
          ref.read(memberPositionsProvider.notifier).removeMember(leftId);
          ref.read(memberRoutesProvider.notifier).removeMember(leftId);
        }
        state = state.copyWith(
          members: state.members.where((id) => id != leftId).toList(),
        );
        break;

      case 'room_left':
        ref.read(memberPositionsProvider.notifier).clear();
        ref.read(memberRoutesProvider.notifier).clear();
        state = state.copyWith(
          status: RoomStatus.disconnected,
          roomCode: null,
          members: [],
        );
        break;

      case 'member_position':
        final memberId = msg['userId'] as String?;
        final lat = (msg['lat'] as num?)?.toDouble();
        final lng = (msg['lng'] as num?)?.toDouble();
        if (memberId == null || lat == null || lng == null) return;

        ref.read(memberPositionsProvider.notifier).update(memberId, lat, lng);
        ref.read(memberRoutesProvider.notifier).addPoint(memberId, lat, lng);
        break;

      case 'error':
        state = state.copyWith(error: msg['message'] as String?);
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ws.dispose();
    super.dispose();
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(ref);
});
