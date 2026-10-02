import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/trip_history_model.dart';
import 'package:live_tracker/screens/history/trip_history_screen.dart';

void main() {
  group('TripCustomTitleAndSortingTest', () {
    test('CompletedTrip preserves customTitle and falls back to displayTitle', () {
      final now = DateTime.now();
      final withTitle = CompletedTrip(
        id: 't_custom',
        customTitle: 'Touring Puncak Asik',
        startTime: now,
        endTime: now.add(const Duration(hours: 2)),
        durationSeconds: 7200,
        distanceMeters: 45000.0,
        avgSpeedKmh: 22.5,
        maxSpeedKmh: 55.0,
        routePoints: const [],
      );

      expect(withTitle.customTitle, 'Touring Puncak Asik');
      expect(withTitle.displayTitle, 'Touring Puncak Asik');

      final serialized = withTitle.toMap();
      expect(serialized['title'], 'Touring Puncak Asik');

      final deserialized = CompletedTrip.fromMap(serialized);
      expect(deserialized.customTitle, 'Touring Puncak Asik');
      expect(deserialized.displayTitle, 'Touring Puncak Asik');

      final withoutTitle = withTitle.copyWith(customTitle: () => null);
      expect(withoutTitle.customTitle, isNull);
      expect(withoutTitle.displayTitle, contains('Trip'));
    });

    test('Trip sorting sorts correctly by newest, distance, and duration', () {
      final now = DateTime.now();
      final t1 = CompletedTrip(
        id: 't1',
        startTime: now.subtract(const Duration(days: 2)),
        endTime: now.subtract(const Duration(days: 2)).add(const Duration(minutes: 30)),
        durationSeconds: 1800,
        distanceMeters: 10000.0,
        avgSpeedKmh: 20.0,
        maxSpeedKmh: 35.0,
        routePoints: const [],
      );

      final t2 = CompletedTrip(
        id: 't2',
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now.subtract(const Duration(days: 1)).add(const Duration(minutes: 60)),
        durationSeconds: 3600,
        distanceMeters: 5000.0,
        avgSpeedKmh: 5.0,
        maxSpeedKmh: 15.0,
        routePoints: const [],
      );

      final t3 = CompletedTrip(
        id: 't3',
        startTime: now,
        endTime: now.add(const Duration(minutes: 15)),
        durationSeconds: 900,
        distanceMeters: 25000.0,
        avgSpeedKmh: 30.0,
        maxSpeedKmh: 50.0,
        routePoints: const [],
      );

      final list = [t1, t2, t3];

      // Newest first
      final byNewest = List<CompletedTrip>.from(list)..sort((a, b) => b.startTime.compareTo(a.startTime));
      expect(byNewest.map((t) => t.id).toList(), ['t3', 't2', 't1']);

      // Longest distance
      final byDistance = List<CompletedTrip>.from(list)..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
      expect(byDistance.map((t) => t.id).toList(), ['t3', 't1', 't2']);

      // Longest duration
      final byDuration = List<CompletedTrip>.from(list)..sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
      expect(byDuration.map((t) => t.id).toList(), ['t2', 't1', 't3']);
    });
  });
}
