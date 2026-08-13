import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/route_history_provider.dart';

class RoutePolylineLayer extends ConsumerWidget {
  const RoutePolylineLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeHistory = ref.watch(routeHistoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (routeHistory.length < 2) return const SizedBox.shrink();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: routeHistory,
          strokeWidth: 5.0,
          color: colorScheme.primary.withOpacity(0.7),
          pattern: const StrokePattern.dotted(),
        ),
      ],
    );
  }
}
