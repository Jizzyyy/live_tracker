import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../room/providers/member_routes_provider.dart';
import 'member_markers_layer.dart';

class MemberRouteLayer extends ConsumerWidget {
  const MemberRouteLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberRoutes = ref.watch(memberRoutesProvider);

    if (memberRoutes.isEmpty) return const SizedBox.shrink();

    final polylines = memberRoutes.entries
        .where((entry) => entry.value.length >= 2)
        .map((entry) {
      final userId = entry.key;
      final route = entry.value;
      final color = MemberMarkersLayer.getColorForUser(userId);

      return Polyline(
        points: route,
        strokeWidth: 3.0,
        color: color.withValues(alpha: 0.4),
        pattern: const StrokePattern.solid(),
      );
    }).toList();

    return RepaintBoundary(
      child: PolylineLayer(polylines: polylines),
    );
  }
}
