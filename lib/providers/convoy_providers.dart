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

// --- Dynamic Convoy Span (Leader to Sweeper Formation Distance) ---
@immutable
class ConvoySpanState {
  final bool hasFormation;
  final double spanDistanceMeters;
  final String? leaderName;
  final String? sweeperName;
  final bool isSpanExcessive;

  const ConvoySpanState({
    this.hasFormation = false,
    this.spanDistanceMeters = 0.0,
    this.leaderName,
    this.sweeperName,
    this.isSpanExcessive = false,
  });

  String get formattedSpan {
    if (spanDistanceMeters < 1000) return '${spanDistanceMeters.toStringAsFixed(0)} m';
    return '${(spanDistanceMeters / 1000).toStringAsFixed(2)} km';
  }
}

final convoySpanProvider = Provider<ConvoySpanState>((ref) {
  final posAsync = ref.watch(locationStreamProvider);
  final myRole = ref.watch(appSettingsProvider.select((s) => s.convoyRole));
  final myName = ref.watch(appSettingsProvider.select((s) => s.userName.trim()));
  final members = ref.watch(roomProvider.select((r) => r.members.values.toList()));
  final inRoom = ref.watch(roomProvider.select((r) => r.roomCode != null));

  if (!inRoom) return const ConvoySpanState();

  LatLng? leaderPos;
  String? leaderName;
  LatLng? sweeperPos;
  String? sweeperName;

  if (posAsync.hasValue) {
    final myPos = LatLng(posAsync.value!.latitude, posAsync.value!.longitude);
    final effectiveMyName = myName.isNotEmpty ? myName : 'YOU';
    if (myRole == ConvoyRole.leader) {
      leaderPos = myPos;
      leaderName = effectiveMyName;
    } else if (myRole == ConvoyRole.sweeper) {
      sweeperPos = myPos;
      sweeperName = effectiveMyName;
    }
  }

  for (final m in members) {
    final mPos = LatLng(m.latitude, m.longitude);
    final mName = (m.name != null && m.name!.trim().isNotEmpty) ? m.name!.trim() : 'User ${m.id}';
    if (m.role == ConvoyRole.leader && leaderPos == null) {
      leaderPos = mPos;
      leaderName = mName;
    } else if (m.role == ConvoyRole.sweeper && sweeperPos == null) {
      sweeperPos = mPos;
      sweeperName = mName;
    }
  }

  if (leaderPos != null && sweeperPos != null) {
    const distCalc = Distance();
    final spanMeters = distCalc.as(LengthUnit.Meter, leaderPos, sweeperPos);
    return ConvoySpanState(
      hasFormation: true,
      spanDistanceMeters: spanMeters,
      leaderName: leaderName,
      sweeperName: sweeperName,
      isSpanExcessive: spanMeters > 1500.0,
    );
  }

  return const ConvoySpanState();
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
