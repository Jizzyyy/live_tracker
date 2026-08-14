import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../providers/location_provider.dart';
import '../../../../shared/widgets/cyber_glass.dart';

class AutoCenterButton extends ConsumerWidget {
  const AutoCenterButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLatLng = ref.watch(currentLatLngProvider);

    return GestureDetector(
      onTap: () {
        if (currentLatLng != null) {
          mapController.move(currentLatLng, MapDefaults.focusedZoom);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menunggu sinyal GPS...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: CyberGlassPanel(
          borderRadius: 22.0,
          padding: EdgeInsets.zero,
          child: Center(
            child: Icon(
              currentLatLng != null ? Icons.my_location : Icons.location_searching,
              color: currentLatLng != null 
                  ? const Color(0xFF00E5FF) 
                  : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
