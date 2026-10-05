import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/models/trip_history_model.dart';

void main() {
  group('SmartAutoPauseDetectionTest', () {
    test('TripSession model accurately maintains isAutoPaused state', () {
      const initial = TripSession(
        state: TripSessionState.active,
        distanceMeters: 4500.0,
        activeDurationSeconds: 600,
        currentSpeedKmh: 28.5,
        avgSpeedKmh: 27.0,
        isAutoPaused: false,
      );

      expect(initial.isAutoPaused, isFalse);

      final paused = initial.copyWith(
        isAutoPaused: true,
        currentSpeedKmh: 0.0,
      );

      expect(paused.isAutoPaused, isTrue);
      expect(paused.distanceMeters, 4500.0);
      expect(paused.activeDurationSeconds, 600);
      expect(paused.currentSpeedKmh, 0.0);

      final resumed = paused.copyWith(
        isAutoPaused: false,
        currentSpeedKmh: 22.0,
      );

      expect(resumed.isAutoPaused, isFalse);
      expect(resumed.currentSpeedKmh, 22.0);
    });

    test('CompletedTrip movingDurationSeconds filters out stationary durations', () {
      final now = DateTime.now();
      final points = <RoutePoint>[];

      // 10 moving points (1 second apart, speed 25 km/h)
      for (int i = 0; i < 10; i++) {
        points.add(RoutePoint(
          latitude: -6.2000 + (i * 0.0001),
          longitude: 106.8000,
          timestamp: now.millisecondsSinceEpoch + (i * 1000),
          speed: 25.0,
        ));
      }

      // 10 stationary points (1 second apart, speed 0.0 km/h)
      for (int i = 10; i < 20; i++) {
        points.add(RoutePoint(
          latitude: -6.2009,
          longitude: 106.8000,
          timestamp: now.millisecondsSinceEpoch + (i * 1000),
          speed: 0.0,
        ));
      }

      final trip = CompletedTrip(
        id: 'trip_autopause_test',
        startTime: now,
        endTime: now.add(const Duration(seconds: 20)),
        durationSeconds: 20,
        distanceMeters: 500.0,
        avgSpeedKmh: 12.5,
        maxSpeedKmh: 25.0,
        routePoints: points,
      );

      // Moving duration should be roughly 9-10 seconds, not the full 20 seconds
      expect(trip.movingDurationSeconds, inInclusiveRange(9, 10));
      expect(trip.stoppedDurationSeconds, inInclusiveRange(10, 11));
      expect(trip.formattedMovingDuration, contains('00m'));
    });
  });
}
