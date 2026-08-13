import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

const _maxRoutePoints = 500;

/// Menyimpan riwayat perjalanan semua anggota room lainnya
class MemberRoutesNotifier extends StateNotifier<Map<String, List<LatLng>>> {
  MemberRoutesNotifier() : super({});

  void addPoint(String userId, double lat, double lng) {
    final point = LatLng(lat, lng);
    final currentRoute = state[userId] ?? [];

    if (currentRoute.isNotEmpty &&
        currentRoute.last.latitude == point.latitude &&
        currentRoute.last.longitude == point.longitude) {
      return;
    }

    final updated = [...currentRoute, point];
    state = {
      ...state,
      userId: updated.length > _maxRoutePoints
          ? updated.sublist(updated.length - _maxRoutePoints)
          : updated,
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
