import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/trip_history_model.dart';

void main() {
  group('ElevationSmootherAndSplitsTest', () {
    test('Calculates 1km splits correctly across multi-kilometer trip', () {
      final now = DateTime.now();
      // Generate route points for ~2.5 km trip
      final routePoints = <RoutePoint>[];
      // 0 to 25 points, each ~100m apart (0.001 deg lat ~= 111m)
      for (int i = 0; i <= 25; i++) {
        routePoints.add(RoutePoint(
          latitude: -6.2000 - (i * 0.0009), // ~100m each
          longitude: 106.8000,
          timestamp: 1000000 + (i * 30000), // 30s each -> ~5 min per km
          altitude: 10.0 + (i * 1.5), // climbing +1.5m per 100m
          speed: 12.0,
        ));
      }

      final trip = CompletedTrip(
        id: 'test_splits_trip',
        startTime: now.subtract(const Duration(minutes: 15)),
        endTime: now,
        durationSeconds: 900,
        distanceMeters: 2500.0,
        avgSpeedKmh: 10.0,
        maxSpeedKmh: 15.0,
        routePoints: routePoints,
      );

      final splits = trip.splits;
      expect(splits.length, 2); // 2 full kilometers completed

      // 1st km split
      expect(splits[0].kilometer, 1);
      expect(splits[0].durationSeconds, greaterThan(0));
      expect(splits[0].formattedPace, isNotEmpty);
      expect(splits[0].elevationChangeMeters, greaterThan(0));
      expect(splits[0].formattedElevation, contains('+'));

      // 2nd km split
      expect(splits[1].kilometer, 2);
      expect(splits[1].durationSeconds, greaterThan(0));
    });

    test('Filters out sub-1.5m micro-jitter in elevation calculation', () {
      final now = DateTime.now();
      final jitteryPoints = [
        RoutePoint(latitude: -6.2000, longitude: 106.8000, timestamp: 1000, altitude: 20.0),
        RoutePoint(latitude: -6.2001, longitude: 106.8000, timestamp: 2000, altitude: 20.4), // +0.4m (should ignore)
        RoutePoint(latitude: -6.2002, longitude: 106.8000, timestamp: 3000, altitude: 20.1), // -0.3m (should ignore)
        RoutePoint(latitude: -6.2003, longitude: 106.8000, timestamp: 4000, altitude: 20.6), // +0.5m (should ignore)
        RoutePoint(latitude: -6.2004, longitude: 106.8000, timestamp: 5000, altitude: 23.0), // +3.0m (legit climb)
      ];

      final trip = CompletedTrip(
        id: 'test_jitter_trip',
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now,
        durationSeconds: 300,
        distanceMeters: 500.0,
        avgSpeedKmh: 6.0,
        maxSpeedKmh: 8.0,
        routePoints: jitteryPoints,
      );

      // Total gain should be ~3.0m, NOT bloated by 0.4 + 0.5 + 2.9
      expect(trip.elevationGainMeters, closeTo(3.0, 0.5));
    });
  });
}
