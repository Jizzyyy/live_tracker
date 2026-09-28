import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:live_tracker/utils/map_bounds_helper.dart';

void main() {
  group('calculateSafeBounds Utility Tests', () {
    test('Handles empty points list without throwing and provides default fallback bounds', () {
      final bounds = calculateSafeBounds([]);
      expect(bounds.north, greaterThan(bounds.south));
      expect(bounds.east, greaterThan(bounds.west));
      expect((bounds.north - bounds.south).abs(), closeTo(0.010, 0.001));
    });

    test('Single coordinate expands by minDeltaDegrees to prevent zero-area box', () {
      const singlePoint = LatLng(-6.2088, 106.8456);
      final bounds = calculateSafeBounds([singlePoint], minDeltaDegrees: 0.005);

      expect(bounds.north, closeTo(-6.2088 + 0.005, 0.0001));
      expect(bounds.south, closeTo(-6.2088 - 0.005, 0.0001));
      expect(bounds.east, closeTo(106.8456 + 0.005, 0.0001));
      expect(bounds.west, closeTo(106.8456 - 0.005, 0.0001));
      expect(bounds.center.latitude, closeTo(singlePoint.latitude, 0.0001));
      expect(bounds.center.longitude, closeTo(singlePoint.longitude, 0.0001));
    });

    test('Identical multiple coordinates expand safely', () {
      final identicalPoints = [
        const LatLng(-6.2000, 106.8000),
        const LatLng(-6.2000, 106.8000),
        const LatLng(-6.2000, 106.8000),
      ];

      final bounds = calculateSafeBounds(identicalPoints, minDeltaDegrees: 0.008);
      expect((bounds.north - bounds.south).abs(), closeTo(0.008, 0.0001));
      expect((bounds.east - bounds.west).abs(), closeTo(0.008, 0.0001));
    });

    test('Multi-point distinct coordinates maintain true bounding box', () {
      final route = [
        const LatLng(-6.1000, 106.7000),
        const LatLng(-6.2000, 106.8500),
        const LatLng(-6.3000, 106.9000),
      ];

      final bounds = calculateSafeBounds(route);
      expect(bounds.north, closeTo(-6.1000, 0.0001));
      expect(bounds.south, closeTo(-6.3000, 0.0001));
      expect(bounds.west, closeTo(106.7000, 0.0001));
      expect(bounds.east, closeTo(106.9000, 0.0001));
    });
  });
}
