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
/// Note: Foreground notifications are handled exclusively by BackgroundTrackingManager
/// to avoid duplicate hardware streams and notification channel conflicts.
LocationSettings _buildLocationSettings() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 2),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      activityType: ActivityType.fitness,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );
  }

  return const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );
}

/// Returns a stream of GPS positions with platform-optimized settings.
/// On Android: uses foreground service notification to prevent OS from killing GPS.
/// On iOS: uses fitness activity type for battery-optimized continuous tracking.
Stream<Position> positionStream() {
  return Geolocator.getPositionStream(
    locationSettings: _buildLocationSettings(),
  );
}
