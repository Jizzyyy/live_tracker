import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Geodesic navigation helper providing precise great-circle forward azimuth
/// (initial bearing), angular interpolation, and cardinal conversions.
class GeoBearingHelper {
  /// Computes the great-circle initial bearing (forward azimuth) from [start] to [dest]
  /// in degrees normalized to [0.0, 360.0).
  ///
  /// Returns 0.0 if [start] and [dest] represent the same coordinates.
  static double calculateBearing(LatLng start, LatLng dest) {
    return calculateBearingRaw(
      start.latitude,
      start.longitude,
      dest.latitude,
      dest.longitude,
    );
  }

  /// Computes the great-circle initial bearing from raw coordinate degrees.
  static double calculateBearingRaw(
    double startLatDeg,
    double startLngDeg,
    double destLatDeg,
    double destLngDeg,
  ) {
    final dLat = destLatDeg - startLatDeg;
    final dLng = destLngDeg - startLngDeg;

    // Fast-path: exactly identical points
    if (dLat == 0.0 && dLng == 0.0) return 0.0;

    final startLat = startLatDeg * pi / 180.0;
    final startLng = startLngDeg * pi / 180.0;
    final destLat = destLatDeg * pi / 180.0;
    final destLng = destLngDeg * pi / 180.0;

    final deltaLng = destLng - startLng;
    final y = sin(deltaLng) * cos(destLat);
    final x = cos(startLat) * sin(destLat) - sin(startLat) * cos(destLat) * cos(deltaLng);
    final initialBearing = atan2(y, x);

    return (initialBearing * 180.0 / pi + 360.0) % 360.0;
  }

  /// Calculates the shortest angular delta (in degrees) to rotate from [currentDeg]
  /// to [targetDeg], constrained to range [-180.0, 180.0].
  ///
  /// Positive value indicates clockwise rotation, negative indicates counter-clockwise.
  /// This prevents the 350-degree reverse spin when crossing North (0° / 360° boundary).
  static double calculateShortestAngleDelta(double currentDeg, double targetDeg) {
    return (targetDeg - currentDeg + 540.0) % 360.0 - 180.0;
  }

  /// Converts a compass bearing in degrees to Indonesian 8-point cardinal abbreviation.
  /// (U = Utara, TL = Timur Laut, T = Timur, TG = Tenggara, S = Selatan,
  ///  BD = Barat Daya, B = Barat, BL = Barat Laut).
  static String bearingToCardinal(double bearing) {
    const cardinals = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL', 'U'];
    final normalized = (bearing % 360.0 + 360.0) % 360.0;
    return cardinals[((normalized + 22.5) % 360.0 ~/ 45.0)];
  }
}
