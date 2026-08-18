import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../providers/tracker_providers.dart';
import '../utils/ui_helpers.dart';
import '../utils/custom_snackbar.dart';

class AutoCenterButton extends ConsumerWidget {
  final MapController mapController;
  const AutoCenterButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(locationStreamProvider);
    final isAutoFollow = ref.watch(autoFollowProvider);

    return PremiumGlass(
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
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
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            posAsync.hasValue ? (isAutoFollow ? Icons.my_location : Icons.location_searching) : Icons.location_disabled,
            size: 20,
            color: isAutoFollow ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
