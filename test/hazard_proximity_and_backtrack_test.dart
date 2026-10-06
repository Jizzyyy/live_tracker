import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/models/trip_history_model.dart';
import 'package:live_tracker/providers/tracker_providers.dart';
import 'package:live_tracker/utils/trail_backtracker.dart';

void main() {
  group('HazardProximityAndBacktrackTest', () {
    test('HazardProximityState formats distance correctly', () {
      final hazardPoi = SharedPoi(
        id: 'h_1',
        title: 'Pohon Tumbang',
        latitude: -6.2000,
        longitude: 106.8000,
        category: PoiCategory.hazard,
        createdBy: 'Scout 1',
        createdAt: DateTime.now(),
      );

      final stateClose = HazardProximityState(
        isApproaching: true,
        distanceMeters: 120.0,
        hazardPoi: hazardPoi,
      );
      expect(stateClose.isApproaching, isTrue);
      expect(stateClose.formattedDistance, '120 m');

      final stateFar = HazardProximityState(
        isApproaching: false,
        distanceMeters: 1450.0,
        hazardPoi: hazardPoi,
      );
      expect(stateFar.isApproaching, isFalse);
      expect(stateFar.formattedDistance, '1.45 km');
    });

    test('TrailBacktracker generates inverted reverse path accurately', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final points = [
        RoutePoint(latitude: -6.2001, longitude: 106.8001, timestamp: now),
        RoutePoint(latitude: -6.2002, longitude: 106.8002, timestamp: now + 1000),
        RoutePoint(latitude: -6.2003, longitude: 106.8003, timestamp: now + 2000),
      ];

      final reverse = TrailBacktracker.generateReversePath(points);
      expect(reverse.length, 3);
      expect(reverse.first.latitude, -6.2003);
      expect(reverse.first.longitude, 106.8003);
      expect(reverse.last.latitude, -6.2001);
      expect(reverse.last.longitude, 106.8001);
    });

    test('TrailBacktracker calculates cross-track deviation and detects off-trail condition', () {
      const trail = [
        LatLng(-6.2000, 106.8000),
        LatLng(-6.2010, 106.8000),
        LatLng(-6.2020, 106.8000),
      ];

      // On trail position (~0m deviation)
      const onTrailPos = LatLng(-6.2010, 106.8000);
      final devOnTrail = TrailBacktracker.calculateCrossTrackDeviation(onTrailPos, trail);
      expect(devOnTrail, closeTo(0.0, 1.0));

      // Off-trail position (~220m east)
      const offTrailPos = LatLng(-6.2010, 106.8020);
      final devOffTrail = TrailBacktracker.calculateCrossTrackDeviation(offTrailPos, trail);
      expect(devOffTrail, greaterThan(80.0));
    });

    test('TrailBacktracker.computeBacktrack yields comprehensive backtrack state', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final points = [
        RoutePoint(latitude: -6.2000, longitude: 106.8000, timestamp: now),
        RoutePoint(latitude: -6.2010, longitude: 106.8000, timestamp: now + 1000),
        RoutePoint(latitude: -6.2020, longitude: 106.8000, timestamp: now + 2000),
      ];

      // When inactive, returns default empty state
      final inactiveState = TrailBacktracker.computeBacktrack(
        active: false,
        currentPos: const LatLng(-6.2020, 106.8000),
        outboundPoints: points,
      );
      expect(inactiveState.isBacktrackActive, isFalse);

      // When active, returns populated backtrack state
      final activeState = TrailBacktracker.computeBacktrack(
        active: true,
        currentPos: const LatLng(-6.2020, 106.8000),
        outboundPoints: points,
      );
      expect(activeState.isBacktrackActive, isTrue);
      expect(activeState.originPoint, isNotNull);
      expect(activeState.originPoint!.latitude, -6.2000);
      expect(activeState.distanceToOriginMeters, greaterThan(200.0));
      expect(activeState.isOffTrail, isFalse);
    });
  });
}
