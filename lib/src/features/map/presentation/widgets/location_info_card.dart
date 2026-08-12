import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../providers/location_provider.dart';

class LocationInfoCard extends ConsumerWidget {
  const LocationInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(positionStreamProvider);
    final isLoading = posAsync.isLoading;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 72,
      child: Skeletonizer(
        enabled: isLoading,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.satellite_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLoading
                            ? 'Mencari lokasi...'
                            : posAsync.when(
                                data: (pos) =>
                                    '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
                                loading: () => 'Mencari lokasi...',
                                error: (e, _) => e.toString().replaceFirst('Exception: ', ''),
                              ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoading
                            ? 'Akurasi: --m'
                            : posAsync.when(
                                data: (pos) =>
                                    'Akurasi: ${pos.accuracy.toStringAsFixed(0)}m',
                                loading: () => 'Akurasi: --m',
                                error: (_, __) => 'Periksa izin lokasi di pengaturan',
                              ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
