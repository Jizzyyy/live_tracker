import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/models/tracker_models.dart';

void main() {
  group('CallsignAndMemberInspectionTest', () {
    test('MemberLocation parses custom callsign and falls back gracefully', () {
      final payloadWithName = {
        'userId': 'usr_99',
        'lat': -6.2000,
        'lng': 106.8000,
        'name': 'Ghost Rider',
        'timestamp': 1789000000000,
      };

      final memberWithCallsign = MemberLocation.fromJson(payloadWithName);
      expect(memberWithCallsign.name, 'Ghost Rider');
      expect(memberWithCallsign.id, 'usr_99');

      final payloadWithoutName = {
        'userId': 'usr_100',
        'lat': -6.2000,
        'lng': 106.8000,
        'timestamp': 1789000000000,
      };

      final memberWithoutCallsign = MemberLocation.fromJson(payloadWithoutName);
      expect(memberWithoutCallsign.name, isNull);
    });

    test('Calculates relative distance to member accurately', () {
      const myPos = LatLng(-6.2000, 106.8000);
      const memberPos = LatLng(-6.2050, 106.8000); // ~555m south

      final distMeters = const Distance().as(
        LengthUnit.Meter,
        myPos,
        memberPos,
      );

      expect(distMeters, closeTo(553.0, 5.0));
      final distStr = distMeters < 1000
          ? '${distMeters.toStringAsFixed(0)} m'
          : '${(distMeters / 1000).toStringAsFixed(1)} km';
      expect(distStr, '553 m');
    });
  });
}
