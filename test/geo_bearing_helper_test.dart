import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/utils/geo_bearing_helper.dart';

void main() {
  group('GeoBearingHelper Tests', () {
    const origin = LatLng(-6.2000, 106.8000);

    test('Computes 4 primary cardinal bearings with sub-degree accuracy', () {
      // Due North (Latitude increases)
      const north = LatLng(-6.1000, 106.8000);
      final bNorth = GeoBearingHelper.calculateBearing(origin, north);
      expect(bNorth, closeTo(0.0, 0.5));
      expect(GeoBearingHelper.bearingToCardinal(bNorth), 'U');

      // Due East (Longitude increases)
      const east = LatLng(-6.2000, 106.9000);
      final bEast = GeoBearingHelper.calculateBearing(origin, east);
      expect(bEast, closeTo(90.0, 0.5));
      expect(GeoBearingHelper.bearingToCardinal(bEast), 'T');

      // Due South (Latitude decreases)
      const south = LatLng(-6.3000, 106.8000);
      final bSouth = GeoBearingHelper.calculateBearing(origin, south);
      expect(bSouth, closeTo(180.0, 0.5));
      expect(GeoBearingHelper.bearingToCardinal(bSouth), 'S');

      // Due West (Longitude decreases)
      const west = LatLng(-6.2000, 106.7000);
      final bWest = GeoBearingHelper.calculateBearing(origin, west);
      expect(bWest, closeTo(270.0, 0.5));
      expect(GeoBearingHelper.bearingToCardinal(bWest), 'B');
    });

    test('Computes intermediate diagonal bearings accurately', () {
      // North-East (~45 degrees)
      const northEast = LatLng(-6.1000, 106.9000);
      final bNE = GeoBearingHelper.calculateBearing(origin, northEast);
      expect(bNE, closeTo(45.0, 1.0));
      expect(GeoBearingHelper.bearingToCardinal(bNE), 'TL');

      // South-East (~135 degrees)
      const southEast = LatLng(-6.3000, 106.9000);
      final bSE = GeoBearingHelper.calculateBearing(origin, southEast);
      expect(bSE, closeTo(135.0, 1.0));
      expect(GeoBearingHelper.bearingToCardinal(bSE), 'TG');

      // South-West (~225 degrees)
      const southWest = LatLng(-6.3000, 106.7000);
      final bSW = GeoBearingHelper.calculateBearing(origin, southWest);
      expect(bSW, closeTo(225.0, 1.0));
      expect(GeoBearingHelper.bearingToCardinal(bSW), 'BD');

      // North-West (~315 degrees)
      const northWest = LatLng(-6.1000, 106.7000);
      final bNW = GeoBearingHelper.calculateBearing(origin, northWest);
      expect(bNW, closeTo(315.0, 1.0));
      expect(GeoBearingHelper.bearingToCardinal(bNW), 'BL');
    });

    test('Identical points return 0.0 safely without NaN or division by zero', () {
      expect(GeoBearingHelper.calculateBearing(origin, origin), 0.0);
    });

    test('Shortest angle delta calculates shortest clockwise or counter-clockwise arc', () {
      // Small turn to the right: 10° -> 30° should be +20°
      expect(GeoBearingHelper.calculateShortestAngleDelta(10, 30), closeTo(20.0, 0.01));

      // Small turn to the left: 30° -> 10° should be -20°
      expect(GeoBearingHelper.calculateShortestAngleDelta(30, 10), closeTo(-20.0, 0.01));

      // Crossing North boundary clockwise: 350° -> 10° should be +20° (NOT -340°)
      expect(GeoBearingHelper.calculateShortestAngleDelta(350, 10), closeTo(20.0, 0.01));

      // Crossing North boundary counter-clockwise: 10° -> 350° should be -20° (NOT +340°)
      expect(GeoBearingHelper.calculateShortestAngleDelta(10, 350), closeTo(-20.0, 0.01));

      // Exactly opposite (180°): 0° -> 180°
      expect(GeoBearingHelper.calculateShortestAngleDelta(0, 180).abs(), closeTo(180.0, 0.01));
    });
  });
}
