import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class CompassButton extends StatelessWidget {
  const CompassButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<MapEvent>(
      stream: mapController.mapEventStream,
      builder: (context, snapshot) {
        final rotation = mapController.camera.rotation;
        if (rotation == 0.0) return const SizedBox.shrink();

        // Hapus Positioned dari sini karena dipanggil di dalam Column di map_screen
        return Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: InkWell(
            onTap: () {
              mapController.rotate(0.0);
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Transform.rotate(
                angle: -rotation * (3.1415926535897932 / 180),
                child: Icon(
                  Icons.navigation,
                  size: 20,
                  color: colorScheme.error,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
