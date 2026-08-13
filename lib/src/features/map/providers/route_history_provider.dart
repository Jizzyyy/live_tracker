import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'location_provider.dart';

/// Menyimpan riwayat perjalanan (jejak) user lokal
class RouteHistoryNotifier extends StateNotifier<List<LatLng>> {
  RouteHistoryNotifier() : super([]);

  void addPoint(LatLng point) {
    // Hindari duplikasi titik yang persis sama
    if (state.isNotEmpty && state.last == point) return;
    
    // Simpan titik baru (immutable way)
    state = [...state, point];
  }

  void clear() {
    state = [];
  }
}

final routeHistoryProvider =
    StateNotifierProvider<RouteHistoryNotifier, List<LatLng>>((ref) {
  final notifier = RouteHistoryNotifier();

  // Dengarkan stream posisi lokal, lalu tambahkan ke riwayat
  ref.listen(currentLatLngProvider, (prev, next) {
    if (next != null) {
      notifier.addPoint(next);
    }
  });

  return notifier;
});
