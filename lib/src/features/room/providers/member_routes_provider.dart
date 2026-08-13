import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Menyimpan riwayat perjalanan semua anggota room lainnya
class MemberRoutesNotifier extends StateNotifier<Map<String, List<LatLng>>> {
  MemberRoutesNotifier() : super({});

  void addPoint(String userId, double lat, double lng) {
    final point = LatLng(lat, lng);
    final currentRoute = state[userId] ?? [];
    
    if (currentRoute.isNotEmpty && currentRoute.last == point) return;

    state = {
      ...state,
      userId: [...currentRoute, point],
    };
  }

  void removeMember(String userId) {
    state = Map.from(state)..remove(userId);
  }

  void clear() {
    state = {};
  }
}

final memberRoutesProvider =
    StateNotifierProvider<MemberRoutesNotifier, Map<String, List<LatLng>>>((ref) {
  return MemberRoutesNotifier();
});
