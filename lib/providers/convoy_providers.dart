import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/tracker_models.dart';
import 'tracker_providers.dart';

// --- Convoy Separation Watchdog (500m Safe Radius) ---
@immutable
class ConvoySeparationState {
  final bool isSeparated;
  final double distanceMeters;
  final String? memberId;

  const ConvoySeparationState({
    this.isSeparated = false,
    this.distanceMeters = 0.0,
    this.memberId,
  });
}

final convoySeparationProvider = Provider<ConvoySeparationState>((ref) {
  final posAsync = ref.watch(locationStreamProvider);
  final members = ref.watch(roomProvider.select((r) => r.members.values.toList()));

  if (!posAsync.hasValue || members.isEmpty) {
    return const ConvoySeparationState();
  }

  final pos = posAsync.value!;
  final myLatLng = LatLng(pos.latitude, pos.longitude);
  const distCalc = Distance();

  double minDistance = double.infinity;
  String? nearestMemberId;

  for (final m in members) {
    final d = distCalc.as(LengthUnit.Meter, myLatLng, LatLng(m.latitude, m.longitude));
    if (d < minDistance) {
      minDistance = d;
      nearestMemberId = m.id;
    }
  }

  final isSeparated = minDistance.isFinite && minDistance > 500.0;
  return ConvoySeparationState(
    isSeparated: isSeparated,
    distanceMeters: minDistance.isFinite ? minDistance : 0.0,
    memberId: nearestMemberId,
  );
});

// --- Hazard Proximity Watchdog (150m Alert Geofence) ---
@immutable
class HazardProximityState {
  final bool isApproaching;
  final double distanceMeters;
  final SharedPoi? hazardPoi;

  const HazardProximityState({
    this.isApproaching = false,
    this.distanceMeters = double.infinity,
    this.hazardPoi,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) return '${distanceMeters.toStringAsFixed(0)} m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }
}

final hazardProximityProvider = Provider<HazardProximityState>((ref) {
  final posAsync = ref.watch(locationStreamProvider);
  final pois = ref.watch(roomProvider.select((r) => r.pois.values.toList()));

  if (!posAsync.hasValue || pois.isEmpty) {
    return const HazardProximityState();
  }

  final hazardPois = pois.where((p) => p.category == PoiCategory.hazard).toList();
  if (hazardPois.isEmpty) return const HazardProximityState();

  final myPos = LatLng(posAsync.value!.latitude, posAsync.value!.longitude);
  const distCalc = Distance();

  double minDistance = double.infinity;
  SharedPoi? nearestHazard;

  for (final h in hazardPois) {
    final d = distCalc.as(LengthUnit.Meter, myPos, LatLng(h.latitude, h.longitude));
    if (d < minDistance) {
      minDistance = d;
      nearestHazard = h;
    }
  }

  final isApproaching = minDistance <= 150.0;
  return HazardProximityState(
    isApproaching: isApproaching,
    distanceMeters: minDistance,
    hazardPoi: nearestHazard,
  );
});
