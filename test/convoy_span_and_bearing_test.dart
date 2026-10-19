import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/models/tracker_models.dart';

void main() {
  group('BearingAndMemberLocationTest', () {
    test('MemberLocation accurately parses coordinates, speed, and telemetry from JSON', () {
      final json = {
        'userId': 'rider_1',
        'lat': -6.2000,
        'lng': 106.8000,
        'name': 'Alpha 1',
        'speed': 35.5,
        'heading': 90.0,
        'battery': 85,
      };
      final member = MemberLocation.fromJson(json);
      expect(member.id, 'rider_1');
      expect(member.name, 'Alpha 1');
      expect(member.latitude, -6.2000);
      expect(member.longitude, 106.8000);
      expect(member.speedKmh, 35.5);
      expect(member.heading, 90.0);
      expect(member.batteryPercent, 85);
    });

    test('Bearing calculation returns correct degrees and cardinal points', () {
      double calculateBearing(LatLng start, LatLng dest) {
        final startLat = start.latitudeInRad;
        final startLng = start.longitudeInRad;
        final destLat = dest.latitudeInRad;
        final destLng = dest.longitudeInRad;

        final dLng = destLng - startLng;
        final y = sin(dLng) * cos(destLat);
        final x = cos(startLat) * sin(destLat) - sin(startLat) * cos(destLat) * cos(dLng);
        final initialBearing = atan2(y, x);
        return (initialBearing * 180 / pi + 360) % 360;
      }

      String bearingToCardinal(double bearing) {
        const cardinals = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL', 'U'];
        return cardinals[((bearing + 22.5) % 360 ~/ 45)];
      }

      const pOrigin = LatLng(-6.2000, 106.8000);
      const pNorth = LatLng(-6.1000, 106.8000); // directly North
      const pEast = LatLng(-6.2000, 106.9000);  // directly East
      const pSouth = LatLng(-6.3000, 106.8000); // directly South
      const pWest = LatLng(-6.2000, 106.7000);  // directly West

      final bearingNorth = calculateBearing(pOrigin, pNorth);
      expect(bearingNorth, closeTo(0, 1.0));
      expect(bearingToCardinal(bearingNorth), 'U');

      final bearingEast = calculateBearing(pOrigin, pEast);
      expect(bearingEast, closeTo(90, 1.0));
      expect(bearingToCardinal(bearingEast), 'T');

      final bearingSouth = calculateBearing(pOrigin, pSouth);
      expect(bearingSouth, closeTo(180, 1.0));
      expect(bearingToCardinal(bearingSouth), 'S');

      final bearingWest = calculateBearing(pOrigin, pWest);
      expect(bearingWest, closeTo(270, 1.0));
      expect(bearingToCardinal(bearingWest), 'B');
    });
  });
}
