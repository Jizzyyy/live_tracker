import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../room/providers/member_positions_provider.dart';

class MemberMarkersLayer extends ConsumerWidget {
  const MemberMarkersLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberPositions = ref.watch(memberPositionsProvider);

    return RepaintBoundary(
      child: MarkerLayer(
        markers: memberPositions.entries.map((entry) {
          final userId = entry.key;
          final latLng = entry.value;
          final color = getColorForUser(userId);

          return Marker(
            point: latLng,
            width: 48,
            height: 48,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF12151B),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userId.isNotEmpty ? userId[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Generate consistent color based on user ID string hash
  static Color getColorForUser(String userId) {
    final colors = const [
      Color(0xFFFF1744), // red
      Color(0xFF00E676), // green
      Color(0xFFFFD600), // amber
      Color(0xFFAA00FF), // purple
      Color(0xFF00BCD4), // teal
      Color(0xFFFF6D00), // orange
      Color(0xFF2979FF), // blue
    ];
    final hash = userId.codeUnits.fold<int>(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }
}
