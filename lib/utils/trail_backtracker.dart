import 'package:latlong2/latlong.dart';
import '../models/trip_history_model.dart';

class BacktrackState {
  final bool isBacktrackActive;
  final List<LatLng> reversePath;
  final LatLng? originPoint;
  final double distanceToOriginMeters;
  final double crossTrackDeviationMeters;
  final bool isOffTrail; // > 80m from recorded path

  const BacktrackState({
    this.isBacktrackActive = false,
    this.reversePath = const [],
    this.originPoint,
    this.distanceToOriginMeters = 0.0,
    this.crossTrackDeviationMeters = 0.0,
    this.isOffTrail = false,
  });

  String get formattedDistanceToOrigin {
    if (distanceToOriginMeters < 1000) return '${distanceToOriginMeters.toStringAsFixed(0)} m';
    return '${(distanceToOriginMeters / 1000).toStringAsFixed(2)} km';
  }
}

class TrailBacktracker {
  static const double offTrailThresholdMeters = 80.0;
  static const Distance _distCalc = Distance();

  /// Inverts the recorded route points into a return navigation breadcrumb trail
  static List<LatLng> generateReversePath(List<RoutePoint> routePoints) {
    if (routePoints.length < 2) return const [];
    return routePoints.reversed.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  /// Calculates the minimum perpendicular/cross-track deviation distance from the recorded trail
  static double calculateCrossTrackDeviation(LatLng currentPos, List<LatLng> path) {
    if (path.isEmpty) return 0.0;
    double minDistance = double.infinity;
    for (final pt in path) {
      final d = _distCalc.as(LengthUnit.Meter, currentPos, pt);
      if (d < minDistance) {
        minDistance = d;
      }
    }
    return minDistance.isFinite ? minDistance : 0.0;
  }

  /// Computes full backtrack navigation state
  static BacktrackState computeBacktrack({
    required bool active,
    required LatLng? currentPos,
    required List<RoutePoint> outboundPoints,
  }) {
    if (!active || outboundPoints.length < 2 || currentPos == null) {
      return const BacktrackState();
    }

    final reversePath = generateReversePath(outboundPoints);
    final origin = LatLng(outboundPoints.first.latitude, outboundPoints.first.longitude);
    final distToOrigin = _distCalc.as(LengthUnit.Meter, currentPos, origin);
    final deviation = calculateCrossTrackDeviation(currentPos, reversePath);

    return BacktrackState(
      isBacktrackActive: true,
      reversePath: reversePath,
      originPoint: origin,
      distanceToOriginMeters: distToOrigin,
      crossTrackDeviationMeters: deviation,
      isOffTrail: deviation > offTrailThresholdMeters,
    );
  }
}
