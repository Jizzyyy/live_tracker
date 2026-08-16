import 'package:latlong2/latlong.dart';

class PolylineSimplifier {
  static const Distance _distCalc = Distance();

  /// Fast Distance-threshold filtering for live GPS streaming (O(N))
  /// Filters out jitter and points closer than [minDistanceMeters].
  static List<LatLng> filterDisplacement(List<LatLng> points, {double minDistanceMeters = 2.5}) {
    if (points.length < 2) return points;
    final List<LatLng> filtered = [points.first];

    for (int i = 1; i < points.length; i++) {
      final double dist = _distCalc.as(LengthUnit.Meter, filtered.last, points[i]);
      if (dist >= minDistanceMeters) {
        filtered.add(points[i]);
      }
    }
    return filtered;
  }

  /// Ramer-Douglas-Peucker (RDP) Algorithm for high-performance polyline decimation
  /// Reduces thousands of historical points for 60/120 FPS map rendering.
  static List<LatLng> simplifyRdp(List<LatLng> points, {double epsilonMeters = 3.0}) {
    if (points.length <= 2) return points;

    double maxDistance = 0.0;
    int maxIndex = 0;
    final LatLng first = points.first;
    final LatLng last = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final double distance = _perpendicularDistanceMeters(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxDistance > epsilonMeters) {
      final List<LatLng> firstSub = simplifyRdp(points.sublist(0, maxIndex + 1), epsilonMeters: epsilonMeters);
      final List<LatLng> secondSub = simplifyRdp(points.sublist(maxIndex), epsilonMeters: epsilonMeters);

      return [...firstSub.sublist(0, firstSub.length - 1), ...secondSub];
    } else {
      return [first, last];
    }
  }

  static double _perpendicularDistanceMeters(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final double lineLength = _distCalc.as(LengthUnit.Meter, lineStart, lineEnd);
    if (lineLength == 0.0) {
      return _distCalc.as(LengthUnit.Meter, point, lineStart);
    }

    final double d13 = _distCalc.as(LengthUnit.Meter, lineStart, point) / 6371000.0;
    final double brng12 = _distCalc.bearing(lineStart, lineEnd) * (3.1415926535897932 / 180.0);
    final double brng13 = _distCalc.bearing(lineStart, point) * (3.1415926535897932 / 180.0);

    final double dxt = (d13 * (brng13 - brng12).abs()).abs() * 6371000.0;
    return dxt;
  }
}
