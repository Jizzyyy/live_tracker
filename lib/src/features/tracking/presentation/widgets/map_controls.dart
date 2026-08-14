import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/widgets/cyber_glass.dart';
import '../../providers/tracking_providers.dart';

class MapCompassControl extends StatelessWidget {
  final MapController mapController;
  const MapCompassControl({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapEvent>(
      stream: mapController.mapEventStream,
      builder: (context, snapshot) {
        final rotation = mapController.camera.rotation;
        if (rotation == 0.0) return const SizedBox.shrink();

        return CyberGlassPanel(
          borderRadius: 20.0,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => mapController.rotate(0.0),
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Transform.rotate(
                angle: -rotation * (3.1415926535897932 / 180),
                child: const Icon(Icons.navigation, size: 20, color: Color(0xFFFF1744)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AutoCenterButton extends ConsumerWidget {
  final MapController mapController;
  const AutoCenterButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(positionStreamProvider);

    return CyberGlassPanel(
      borderRadius: 24.0,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          final pos = posAsync.valueOrNull;
          if (pos != null) {
            mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Acquiring GPS Signal...'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF12151B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            posAsync.hasValue ? Icons.my_location : Icons.location_searching,
            size: 20,
            color: posAsync.hasValue ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
