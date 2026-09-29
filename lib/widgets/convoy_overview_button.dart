import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../providers/tracker_providers.dart';
import '../utils/custom_snackbar.dart';
import '../utils/map_bounds_helper.dart';

class ConvoyOverviewButton extends ConsumerWidget {
  final MapController mapController;

  const ConvoyOverviewButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(roomProvider.select((r) => r.members.values.toList()));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (members.isEmpty) return const SizedBox.shrink();

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
          HapticFeedback.selectionClick();
          final pos = ref.read(locationStreamProvider).valueOrNull;
          final allPoints = <LatLng>[];

          if (pos != null) {
            allPoints.add(LatLng(pos.latitude, pos.longitude));
          }

          for (final m in members) {
            allPoints.add(LatLng(m.latitude, m.longitude));
          }

          if (allPoints.isEmpty) return;

          final bounds = calculateSafeBounds(allPoints, minDeltaDegrees: 0.008);

          // Disable auto-follow to keep overview intact
          ref.read(autoFollowProvider.notifier).state = false;

          mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(72),
            ),
          );

          CustomSnackbar.show(
            context,
            message: 'Tampilan Konvoi: ${allPoints.length} anggota di peta',
            type: SnackbarType.info,
          );
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.groups_rounded,
            size: 22,
            color: isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706),
          ),
        ),
      ),
    );
  }
}
