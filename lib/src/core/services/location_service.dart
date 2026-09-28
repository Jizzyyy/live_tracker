import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Result of a permission check with a user-friendly message.
class PermissionResult {
  const PermissionResult({required this.granted, this.message});
  final bool granted;
  final String? message;
}

/// Checks GPS service and permission status.
/// Returns [PermissionResult] with a human-readable message on failure.
Future<PermissionResult> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    await Geolocator.openLocationSettings();
    return const PermissionResult(
      granted: false,
      message: 'GPS tidak aktif. Silakan nyalakan GPS.',
    );
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return const PermissionResult(
        granted: false,
        message: 'Izin lokasi ditolak.',
      );
    }
  }

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
    return const PermissionResult(
      granted: false,
      message: 'Izin lokasi diblokir permanen. Buka pengaturan untuk mengizinkan.',
    );
  }

  return const PermissionResult(granted: true);
}

/// Returns platform-optimized location settings.
/// When [highAccuracy] is false, uses balanced power mode with wider distance filter.
LocationSettings buildLocationSettings({bool highAccuracy = true}) {
  final accuracy = highAccuracy ? LocationAccuracy.high : LocationAccuracy.balanced;
  final filter = highAccuracy ? 5 : 15;
  final interval = highAccuracy ? const Duration(seconds: 2) : const Duration(seconds: 5);

  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: accuracy,
      distanceFilter: filter,
      intervalDuration: interval,
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return AppleSettings(
      accuracy: accuracy,
      distanceFilter: filter,
      activityType: ActivityType.fitness,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );
  }

  return LocationSettings(
    accuracy: accuracy,
    distanceFilter: filter,
  );
}

/// Returns a stream of GPS positions with platform-optimized settings.
Stream<Position> positionStream({bool highAccuracy = true}) {
  return Geolocator.getPositionStream(
    locationSettings: buildLocationSettings(highAccuracy: highAccuracy),
  );
}
