import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'route_history_provider.dart';

class TripStats {
  const TripStats({
    required this.distanceKm,
    required this.speedKmh,
    required this.duration,
  });
  
  final double distanceKm;
  final double speedKmh;
  final Duration duration;
}

class TripStatsNotifier extends StateNotifier<TripStats> {
  TripStatsNotifier() : super(const TripStats(distanceKm: 0, speedKmh: 0, duration: Duration.zero));

  final _distanceCalculator = const Distance();
  DateTime? _startTime;

  void calculate(List<LatLng> route) {
    if (route.isEmpty) {
      _startTime = null;
      state = const TripStats(distanceKm: 0, speedKmh: 0, duration: Duration.zero);
      return;
    }

    if (_startTime == null) {
      _startTime = DateTime.now();
      return;
    }

    double totalDistanceMeters = 0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistanceMeters += _distanceCalculator.as(
        LengthUnit.Meter,
        route[i],
        route[i + 1],
      );
    }

    final duration = DateTime.now().difference(_startTime!);
    final distanceKm = totalDistanceMeters / 1000;
    
    // Kecepatan = Jarak / Waktu (Jam)
    final hours = duration.inSeconds / 3600;
    final speedKmh = hours > 0 ? distanceKm / hours : 0.0;

    state = TripStats(
      distanceKm: distanceKm,
      speedKmh: speedKmh,
      duration: duration,
    );
  }
}

final tripStatsProvider = StateNotifierProvider<TripStatsNotifier, TripStats>((ref) {
  final notifier = TripStatsNotifier();
  
  ref.listen(routeHistoryProvider, (prev, next) {
    notifier.calculate(next);
  });

  return notifier;
});
