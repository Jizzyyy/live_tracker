import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';

/// GPS position stream guarded by permission check.
final positionStreamProvider = StreamProvider.autoDispose<Position>((ref) async* {
  // 1. Minta izin dulu
  final result = await ensureLocationPermission();
  
  // 2. Jika gagal, throw error agar statusnya jadi AsyncError
  if (!result.granted) {
    throw Exception(result.message ?? 'Izin lokasi gagal');
  }

  // 3. Jika granted, kembalikan stream posisinya
  yield* positionStream();
});

/// Derived provider: extracts LatLng from raw Position.
final currentLatLngProvider = Provider.autoDispose<LatLng?>((ref) {
  final posAsync = ref.watch(positionStreamProvider);
  return posAsync.whenData((pos) => LatLng(pos.latitude, pos.longitude)).valueOrNull;
});
