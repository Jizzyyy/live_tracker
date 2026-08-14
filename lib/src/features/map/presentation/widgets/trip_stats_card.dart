import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../providers/location_provider.dart';
import '../../providers/trip_stats_provider.dart';

class TripStatsCard extends ConsumerWidget {
  const TripStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(tripStatsProvider);
    final posAsync = ref.watch(positionStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    String formatDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return hours > 0 ? '\$hours:\$minutes:\$seconds' : '\$minutes:\$seconds';
    }

    return Positioned(
      top: 16,
      left: 16,
      right: 72,
      child: Skeletonizer(
        enabled: posAsync.isLoading,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.route_outlined,
                    value: '${stats.distanceKm.toStringAsFixed(2)} km',
                    label: 'Jarak',
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer_outlined,
                    value: formatDuration(stats.duration),
                    label: 'Waktu',
                    color: colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.speed_outlined,
                    value: '${stats.speedKmh.toStringAsFixed(1)} km/h',
                    label: 'Kecepatan',
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
