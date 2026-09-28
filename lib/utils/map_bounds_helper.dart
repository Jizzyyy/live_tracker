import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Computes a safe [LatLngBounds] for a list of [LatLng] points.
/// Ensures that bounding boxes with empty points, single points, or identical coordinates
/// have a minimum padding buffer of ±[minDeltaDegrees] (~550 meters default)
/// to prevent zero-area bounding box division by zero / NaN camera zoom crashes.
LatLngBounds calculateSafeBounds(List<LatLng> points, {double minDeltaDegrees = 0.005}) {
  if (points.isEmpty) {
    return LatLngBounds(
      LatLng(-6.2 - minDeltaDegrees, 106.8 - minDeltaDegrees),
      LatLng(-6.2 + minDeltaDegrees, 106.8 + minDeltaDegrees),
    );
  }

  if (points.length == 1) {
    final pt = points.first;
    return LatLngBounds(
      LatLng(pt.latitude - minDeltaDegrees, pt.longitude - minDeltaDegrees),
      LatLng(pt.latitude + minDeltaDegrees, pt.longitude + minDeltaDegrees),
    );
  }

  final bounds = LatLngBounds.fromPoints(points);
  final latDiff = (bounds.north - bounds.south).abs();
  final lngDiff = (bounds.east - bounds.west).abs();

  if (latDiff < minDeltaDegrees || lngDiff < minDeltaDegrees) {
    final center = bounds.center;
    final halfPad = minDeltaDegrees / 2;
    return LatLngBounds(
      LatLng(center.latitude - halfPad, center.longitude - halfPad),
      LatLng(center.latitude + halfPad, center.longitude + halfPad),
    );
  }

  return bounds;
}
