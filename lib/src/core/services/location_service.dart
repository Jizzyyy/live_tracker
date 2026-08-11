import 'package:geolocator/geolocator.dart';

/// Ensures GPS is enabled and permission is granted.
/// Returns true when location is usable.
Future<bool> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    await Geolocator.openLocationSettings();
    return false;
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return false;
  }

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
    return false;
  }

  return true;
}

/// Returns a stream of GPS positions, updating when user moves >= 5 meters.
Stream<Position> positionStream() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  );
}
