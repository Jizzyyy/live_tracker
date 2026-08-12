import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/websocket_service.dart';

class MemberPositionsNotifier extends StateNotifier<Map<String, LatLng>> {
  MemberPositionsNotifier() : super({});

  void update(String userId, double lat, double lng) {
    state = {...state, userId: LatLng(lat, lng)};
  }

  void removeMember(String userId) {
    state = Map.from(state)..remove(userId);
  }

  void clear() {
    state = {};
  }
}

final memberPositionsProvider =
    StateNotifierProvider<MemberPositionsNotifier, Map<String, LatLng>>((ref) {
  return MemberPositionsNotifier();
});
