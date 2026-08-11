import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';

/// Raw GPS position stream. Auto-cancels when no widget is watching.
final positionStreamProvider = StreamProvider.autoDispose<Position>((ref) {
  return positionStream();
});
