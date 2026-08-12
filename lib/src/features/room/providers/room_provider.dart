import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/websocket_service.dart';

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
  RoomNotifier() : super(const RoomState());

  final _ws = WebSocketService();
  StreamSubscription? _sub;

  void connect(String serverUrl) {
    state = state.copyWith(status: RoomStatus.connecting);
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
    state = state.copyWith(
      status: RoomStatus.disconnected,
      roomCode: null,
      members: [],
    );
  }

  void sendPosition(double lat, double lng) {
    if (state.status != RoomStatus.inRoom) return;
    _ws.send({'type': 'position_update', 'lat': lat, 'lng': lng});
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
        state = state.copyWith(
          members: state.members.where((id) => id != leftId).toList(),
        );
        break;

      case 'room_left':
        state = state.copyWith(
          status: RoomStatus.disconnected,
          roomCode: null,
          members: [],
        );
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
  final notifier = RoomNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
