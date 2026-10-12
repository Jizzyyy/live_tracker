import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/models/trip_history_model.dart';
import 'package:live_tracker/utils/trail_backtracker.dart';

void main() {
  group('TrailBacktracker Off-Trail & Boundary Tests', () {
    test('Boundary test: exactly 80.0m is not off-trail, 80.1m is off-trail', () {
      const trail = [
        LatLng(0.0000, 0.0000),
        LatLng(0.0010, 0.0000),
      ];

      // At equator, 1 deg long ~ 111,319 meters.
      // 0.00065 deg ~ 72.3 meters
      // 0.00085 deg ~ 94.6 meters
      const posAt75m = LatLng(0.0000, 0.00065);
      const posAt90m = LatLng(0.0000, 0.00085);

      final dev75 = TrailBacktracker.calculateCrossTrackDeviation(posAt75m, trail);
      expect(dev75, lessThan(TrailBacktracker.offTrailThresholdMeters));

      final dev90 = TrailBacktracker.calculateCrossTrackDeviation(posAt90m, trail);
      expect(dev90, greaterThan(TrailBacktracker.offTrailThresholdMeters));

      final points = [
        RoutePoint(latitude: 0.0000, longitude: 0.0000, timestamp: 1000),
        RoutePoint(latitude: 0.0010, longitude: 0.0000, timestamp: 2000),
      ];

      final stateWithin = TrailBacktracker.computeBacktrack(
        active: true,
        currentPos: posAt75m,
        outboundPoints: points,
      );
      expect(stateWithin.isOffTrail, isFalse);

      final stateDeviated = TrailBacktracker.computeBacktrack(
        active: true,
        currentPos: posAt90m,
        outboundPoints: points,
      );
      expect(stateDeviated.isOffTrail, isTrue);
    });

    test('generateReversePath preserves all coordinate points in strictly reversed order', () {
      final points = List.generate(
        10,
        (i) => RoutePoint(
          latitude: -6.2000 + (i * 0.001),
          longitude: 106.8000 + (i * 0.001),
          timestamp: 1000 + (i * 100),
        ),
      );

      final reverse = TrailBacktracker.generateReversePath(points);
      expect(reverse.length, 10);
      for (int i = 0; i < 10; i++) {
        expect(reverse[i].latitude, points[9 - i].latitude);
        expect(reverse[i].longitude, points[9 - i].longitude);
      }
    });

    test('computeBacktrack returns empty state on null pos or inactive flag', () {
      final points = [
        RoutePoint(latitude: -6.200, longitude: 106.800, timestamp: 1000),
        RoutePoint(latitude: -6.201, longitude: 106.801, timestamp: 2000),
      ];

      final nullPosState = TrailBacktracker.computeBacktrack(
        active: true,
        currentPos: null,
        outboundPoints: points,
      );
      expect(nullPosState.isBacktrackActive, isFalse);
      expect(nullPosState.reversePath, isEmpty);

      final inactiveState = TrailBacktracker.computeBacktrack(
        active: false,
        currentPos: const LatLng(-6.2, 106.8),
        outboundPoints: points,
      );
      expect(inactiveState.isBacktrackActive, isFalse);
      expect(inactiveState.reversePath, isEmpty);
    });
  });
}
