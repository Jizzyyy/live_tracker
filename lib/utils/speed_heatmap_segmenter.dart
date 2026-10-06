import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_history_model.dart';

class HeatmapSegment {
  final List<LatLng> points;
  final Color color;
  final String tierLabel;

  const HeatmapSegment({
    required this.points,
    required this.color,
    required this.tierLabel,
  });
}

class SpeedHeatmapSegmenter {
  // Speed Tiers:
  // Tier 1 (Slow / Climb / Traffic): < 20 km/h -> Blue
  // Tier 2 (Cruising Pace): 20 - 45 km/h -> Green
  // Tier 3 (Fast Pace): 45 - 75 km/h -> Yellow / Amber
  // Tier 4 (Sprint / High Speed): > 75 km/h -> Crimson Red
  static const Color tierSlowColor = Color(0xFF2979FF);
  static const Color tierCruiseColor = Color(0xFF00E676);
  static const Color tierFastColor = Color(0xFFFFD600);
  static const Color tierSprintColor = Color(0xFFFF1744);

  static Color getColorForSpeed(double speedKmh) {
    if (speedKmh < 20.0) return tierSlowColor;
    if (speedKmh < 45.0) return tierCruiseColor;
    if (speedKmh < 75.0) return tierFastColor;
    return tierSprintColor;
  }

  static String getLabelForSpeed(double speedKmh) {
    if (speedKmh < 20.0) return '< 20 km/h (Slow)';
    if (speedKmh < 45.0) return '20-45 km/h (Cruise)';
    if (speedKmh < 75.0) return '45-75 km/h (Fast)';
    return '> 75 km/h (Sprint)';
  }

  static List<HeatmapSegment> segmentRoute(List<RoutePoint> routePoints) {
    if (routePoints.length < 2) return const [];

    final segments = <HeatmapSegment>[];
    List<LatLng> currentSegmentPoints = [
      LatLng(routePoints.first.latitude, routePoints.first.longitude),
    ];
    Color currentSegmentColor = getColorForSpeed(routePoints.first.speed ?? 0.0);
    String currentTierLabel = getLabelForSpeed(routePoints.first.speed ?? 0.0);

    for (int i = 1; i < routePoints.length; i++) {
      final pt = routePoints[i];
      final ptLatLng = LatLng(pt.latitude, pt.longitude);
      final ptColor = getColorForSpeed(pt.speed ?? 0.0);
      final ptLabel = getLabelForSpeed(pt.speed ?? 0.0);

      if (ptColor == currentSegmentColor) {
        currentSegmentPoints.add(ptLatLng);
      } else {
        currentSegmentPoints.add(ptLatLng); // overlap point to prevent gaps between segments
        segments.add(HeatmapSegment(
          points: List.unmodifiable(currentSegmentPoints),
          color: currentSegmentColor,
          tierLabel: currentTierLabel,
        ));
        currentSegmentPoints = [ptLatLng];
        currentSegmentColor = ptColor;
        currentTierLabel = ptLabel;
      }
    }

    if (currentSegmentPoints.length >= 2) {
      segments.add(HeatmapSegment(
        points: List.unmodifiable(currentSegmentPoints),
        color: currentSegmentColor,
        tierLabel: currentTierLabel,
      ));
    }

    return segments;
  }
}
