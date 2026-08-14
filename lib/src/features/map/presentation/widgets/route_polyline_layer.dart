import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/route_history_provider.dart';

class RoutePolylineLayer extends ConsumerWidget {
  const RoutePolylineLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeHistory = ref.watch(routeHistoryProvider);

    if (routeHistory.length < 2) return const SizedBox.shrink();

    return RepaintBoundary(
      child: PolylineLayer(
        polylines: [
          Polyline(
            points: routeHistory,
            strokeWidth: 4.0,
            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
            pattern: const StrokePattern.solid(),
          ),
        ],
      ),
    );
  }
}
