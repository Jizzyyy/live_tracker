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

    return MarkerLayer(
      markers: memberPositions.entries.map((entry) {
        final userId = entry.key;
        final latLng = entry.value;
        final color = getColorForUser(userId);

        return Marker(
          point: latLng,
          width: 80,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color, width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ],
                ),
                child: Text(
                  userId,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Generate consistent color based on user ID string hash
  static Color getColorForUser(String userId) {
    final colors = [
      Colors.red.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
    ];
    final hash = userId.codeUnits.fold<int>(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }
}
