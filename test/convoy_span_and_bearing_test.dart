import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/providers/tracker_providers.dart';

void main() {
  group('ConvoySpanAndBearingTest', () {
    test('ConvoyRole extension provides correct badge and label text', () {
      expect(ConvoyRole.leader.badgeText, 'LEAD');
      expect(ConvoyRole.leader.label, 'Leader');

      expect(ConvoyRole.sweeper.badgeText, 'SWEEP');
      expect(ConvoyRole.sweeper.label, 'Sweeper');

      expect(ConvoyRole.scout.badgeText, 'SCOUT');
      expect(ConvoyRole.scout.label, 'Scout');

      expect(ConvoyRole.member.badgeText, 'MBR');
      expect(ConvoyRole.member.label, 'Member');
    });

    test('MemberLocation accurately parses ConvoyRole from JSON', () {
      final leadJson = {
        'userId': 'lead_1',
        'lat': -6.2000,
        'lng': 106.8000,
        'role': 'leader',
      };
      final leadMember = MemberLocation.fromJson(leadJson);
      expect(leadMember.role, ConvoyRole.leader);

      final sweepJson = {
        'userId': 'sweep_1',
        'lat': -6.2050,
        'lng': 106.8000,
        'role': 'sweeper',
      };
      final sweepMember = MemberLocation.fromJson(sweepJson);
      expect(sweepMember.role, ConvoyRole.sweeper);

      final defaultJson = {
        'userId': 'mbr_1',
        'lat': -6.2020,
        'lng': 106.8000,
      };
      final defaultMember = MemberLocation.fromJson(defaultJson);
      expect(defaultMember.role, ConvoyRole.member);
    });

    test('ConvoySpanState calculates formatted distance and excess flag', () {
      const normalSpan = ConvoySpanState(
        hasFormation: true,
        spanDistanceMeters: 850.0,
        leaderName: 'Alpha Lead',
        sweeperName: 'Bravo Sweep',
        isSpanExcessive: false,
      );
      expect(normalSpan.formattedSpan, '850 m');
      expect(normalSpan.isSpanExcessive, isFalse);

      const excessiveSpan = ConvoySpanState(
        hasFormation: true,
        spanDistanceMeters: 2450.0,
        leaderName: 'Alpha Lead',
        sweeperName: 'Bravo Sweep',
        isSpanExcessive: true,
      );
      expect(excessiveSpan.formattedSpan, '2.45 km');
      expect(excessiveSpan.isSpanExcessive, isTrue);
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
