import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';

/// Raw GPS position stream. Auto-cancels when no widget is watching.
final positionStreamProvider = StreamProvider.autoDispose<Position>((ref) {
  return positionStream();
});

/// Derived provider: extracts LatLng from raw Position.
/// Returns null until first GPS fix arrives.
final currentLatLngProvider = Provider.autoDispose<LatLng?>((ref) {
  final posAsync = ref.watch(positionStreamProvider);
  return posAsync.whenData((pos) => LatLng(pos.latitude, pos.longitude)).valueOrNull;
});
