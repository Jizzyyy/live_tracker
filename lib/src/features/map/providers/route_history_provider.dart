import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'location_provider.dart';

const _maxRoutePoints = 500;

/// Menyimpan riwayat perjalanan (jejak) user lokal
class RouteHistoryNotifier extends StateNotifier<List<LatLng>> {
  RouteHistoryNotifier() : super([]);

  void addPoint(LatLng point) {
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

  // Listen to raw position stream to access accuracy metadata
  ref.listen(positionStreamProvider, (prev, next) {
    if (next.hasValue) {
      final pos = next.value!;
      // Only record route history if accuracy is better than 30 meters
      // This prevents the "5km jump" bug on initial poor cell-tower fixes
      if (pos.accuracy <= 30.0) {
        notifier.addPoint(LatLng(pos.latitude, pos.longitude));
      }
    }
  });

  return notifier;
});
