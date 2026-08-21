import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../providers/tracker_providers.dart';
import '../utils/custom_snackbar.dart';

class AutoCenterButton extends ConsumerWidget {
  final MapController mapController;
  const AutoCenterButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(locationStreamProvider);
    final isAutoFollow = ref.watch(autoFollowProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Performance Optimization: Use solid translucent circular surface
    // instead of heavy BackdropFilter for small floating button overlays
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark 
            ? const Color(0xFF12151B).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final pos = posAsync.valueOrNull;
          if (pos != null) {
            mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
            ref.read(autoFollowProvider.notifier).state = true;
            CustomSnackbar.show(context, message: 'Auto-follow aktif', type: SnackbarType.success);
          } else {
            CustomSnackbar.show(context, message: 'Menunggu sinyal GPS...', type: SnackbarType.warning);
          }
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            posAsync.hasValue ? (isAutoFollow ? Icons.my_location : Icons.location_searching) : Icons.location_disabled,
            size: 20,
            color: isAutoFollow 
                ? (isDark ? const Color(0xFF00E5FF) : Theme.of(context).colorScheme.primary) 
                : (isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54),
          ),
        ),
      ),
    );
  }
}
