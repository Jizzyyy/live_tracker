import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/trip_history_model.dart';

void main() {
  group('LifetimeTotalsAggregationTest', () {
    test('Correctly aggregates distance, duration, and trip count', () {
      final now = DateTime.now();
      final trips = [
        CompletedTrip(
          id: 'trip_1',
          startTime: now.subtract(const Duration(hours: 3)),
          endTime: now.subtract(const Duration(hours: 2)),
          durationSeconds: 3600, // 1 hr
          distanceMeters: 15400.0, // 15.4 km
          avgSpeedKmh: 15.4,
          maxSpeedKmh: 28.0,
          routePoints: const [],
        ),
        CompletedTrip(
          id: 'trip_2',
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now,
          durationSeconds: 1800, // 0.5 hr
          distanceMeters: 8200.0, // 8.2 km
          avgSpeedKmh: 16.4,
          maxSpeedKmh: 31.0,
          routePoints: const [],
        ),
      ];

      final totalDistM = trips.fold<double>(0.0, (acc, t) => acc + t.distanceMeters);
      final totalSecs = trips.fold<int>(0, (acc, t) => acc + t.durationSeconds);
      final distKm = totalDistM / 1000;
      final totalHours = (totalSecs / 3600).toStringAsFixed(1);

      expect(distKm, closeTo(23.6, 0.01));
      expect(totalHours, '1.5');
      expect(trips.length, 2);
    });

    test('Handles empty trip list gracefully', () {
      final trips = <CompletedTrip>[];
      final totalDistM = trips.fold<double>(0.0, (acc, t) => acc + t.distanceMeters);
      final totalSecs = trips.fold<int>(0, (acc, t) => acc + t.durationSeconds);

      expect(totalDistM, 0.0);
      expect(totalSecs, 0);
    });
  });
}
