import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';

void main() {
  group('Trip Lifecycle State Machine Tests', () {
    test('Initial state is inactive with zero metrics', () {
      const session = TripSession();
      expect(session.state, TripSessionState.inactive);
      expect(session.distanceMeters, 0.0);
      expect(session.activeDurationSeconds, 0);
      expect(session.currentSpeedKmh, 0.0);
      expect(session.avgSpeedKmh, 0.0);
      expect(session.formattedDistance, '0 m');
      expect(session.formattedDuration, '00:00');
    });

    test('Transitions from inactive to active upon start', () {
      const initial = TripSession();
      final active = initial.copyWith(
        state: TripSessionState.active,
        distanceMeters: 120.0,
        activeDurationSeconds: 15,
        currentSpeedKmh: 24.5,
        avgSpeedKmh: 28.8,
      );

      expect(active.state, TripSessionState.active);
      expect(active.distanceMeters, 120.0);
      expect(active.currentSpeedKmh, 24.5);
    });

    test('Transitions from active to paused zeroing current speed while preserving distance and duration', () {
      const active = TripSession(
        state: TripSessionState.active,
        distanceMeters: 4500.0,
        activeDurationSeconds: 600,
        currentSpeedKmh: 28.0,
        avgSpeedKmh: 27.0,
      );

      final paused = active.copyWith(
        state: TripSessionState.paused,
        currentSpeedKmh: 0.0,
      );

      expect(paused.state, TripSessionState.paused);
      expect(paused.currentSpeedKmh, 0.0);
      expect(paused.distanceMeters, 4500.0);
      expect(paused.activeDurationSeconds, 600);
      expect(paused.formattedDistance, '4.50 km');
      expect(paused.formattedDuration, '10:00');
    });

    test('Transitions from paused to active resuming tracking', () {
      const paused = TripSession(
        state: TripSessionState.paused,
        distanceMeters: 4500.0,
        activeDurationSeconds: 600,
        currentSpeedKmh: 0.0,
        avgSpeedKmh: 27.0,
      );

      final resumed = paused.copyWith(
        state: TripSessionState.active,
        currentSpeedKmh: 15.0,
        distanceMeters: 4550.0,
        activeDurationSeconds: 610,
      );

      expect(resumed.state, TripSessionState.active);
      expect(resumed.currentSpeedKmh, 15.0);
      expect(resumed.distanceMeters, 4550.0);
      expect(resumed.activeDurationSeconds, 610);
    });

    test('Transitions to inactive upon stop reset', () {
      const active = TripSession(
        state: TripSessionState.active,
        distanceMeters: 12000.0,
        activeDurationSeconds: 1800,
        currentSpeedKmh: 30.0,
        avgSpeedKmh: 24.0,
      );
      expect(active.state, TripSessionState.active);

      const stopped = TripSession();
      expect(stopped.state, TripSessionState.inactive);
      expect(stopped.distanceMeters, 0.0);
      expect(stopped.activeDurationSeconds, 0);
    });
  });
}
