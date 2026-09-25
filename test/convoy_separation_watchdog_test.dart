import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/providers/tracker_providers.dart';

void main() {
  group('Convoy Separation Watchdog Tests', () {
    const distCalc = Distance();
    const myPos = LatLng(-6.2000, 106.8000);

    test('Identifies safe proximity when nearest member is within 500m', () {
      // ~111m away
      final nearbyMember = MemberLocation(
        id: 'member_alpha',
        latitude: -6.2010,
        longitude: 106.8000,
        lastUpdated: DateTime.now(),
      );

      final distance = distCalc.as(LengthUnit.Meter, myPos, LatLng(nearbyMember.latitude, nearbyMember.longitude));
      expect(distance, lessThan(500.0));

      final state = ConvoySeparationState(
        isSeparated: distance > 500.0,
        distanceMeters: distance,
        memberId: nearbyMember.id,
      );

      expect(state.isSeparated, isFalse);
      expect(state.memberId, 'member_alpha');
    });

    test('Triggers separation alert when nearest member is beyond 500m threshold', () {
      // ~1.1km away
      final farMember = MemberLocation(
        id: 'member_bravo',
        latitude: -6.2100,
        longitude: 106.8000,
        lastUpdated: DateTime.now(),
      );

      final distance = distCalc.as(LengthUnit.Meter, myPos, LatLng(farMember.latitude, farMember.longitude));
      expect(distance, greaterThan(500.0));

      final state = ConvoySeparationState(
        isSeparated: distance > 500.0,
        distanceMeters: distance,
        memberId: farMember.id,
      );

      expect(state.isSeparated, isTrue);
      expect(state.distanceMeters, greaterThan(1000.0));
    });
  });
}
