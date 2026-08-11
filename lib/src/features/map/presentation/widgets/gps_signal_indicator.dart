import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/location_provider.dart';

class GpsSignalIndicator extends ConsumerWidget {
  const GpsSignalIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(positionStreamProvider);

    final (IconData icon, Color color, String tooltip) = posAsync.when(
      data: (pos) {
        if (pos.accuracy <= 10) {
          return (Icons.gps_fixed, Colors.green, 'GPS akurat (${pos.accuracy.toStringAsFixed(0)}m)');
        } else if (pos.accuracy <= 30) {
          return (Icons.gps_not_fixed, Colors.orange, 'GPS sedang (${pos.accuracy.toStringAsFixed(0)}m)');
        }
        return (Icons.gps_not_fixed, Colors.red, 'GPS lemah (${pos.accuracy.toStringAsFixed(0)}m)');
      },
      loading: () => (Icons.gps_off, Colors.grey, 'Mencari GPS...'),
      error: (_, __) => (Icons.gps_off, Colors.red, 'GPS error'),
    );

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
