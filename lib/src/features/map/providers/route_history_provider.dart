import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'location_provider.dart';

const _maxRoutePoints = 500;

/// Menyimpan riwayat perjalanan (jejak) user lokal
class RouteHistoryNotifier extends StateNotifier<List<LatLng>> {
  RouteHistoryNotifier() : super([]);

  void addPoint(LatLng point) {
    // LatLng does not override == — compare coordinates explicitly
    if (state.isNotEmpty &&
        state.last.latitude == point.latitude &&
        state.last.longitude == point.longitude) {
      return;
    }

    final updated = [...state, point];
    state = updated.length > _maxRoutePoints
        ? updated.sublist(updated.length - _maxRoutePoints)
        : updated;
  }

  void clear() {
    state = [];
  }
}

final routeHistoryProvider =
    StateNotifierProvider<RouteHistoryNotifier, List<LatLng>>((ref) {
  final notifier = RouteHistoryNotifier();

  ref.listen(currentLatLngProvider, (prev, next) {
    if (next != null) {
      notifier.addPoint(next);
    }
  });

  return notifier;
});
