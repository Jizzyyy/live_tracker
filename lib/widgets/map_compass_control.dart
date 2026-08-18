import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapCompassControl extends StatelessWidget {
  final MapController mapController;
  const MapCompassControl({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<MapEvent>(
      stream: mapController.mapEventStream,
      builder: (context, snapshot) {
        final rotation = mapController.camera.rotation;
        if (rotation == 0.0) return const SizedBox.shrink();

        // Performance Optimization: Use solid translucent circular surface 
        // instead of heavy BackdropFilter for small map control buttons
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
            onTap: () => mapController.rotate(0.0),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Transform.rotate(
                angle: -rotation * (3.1415926535897932 / 180),
                child: Icon(
                  Icons.navigation, 
                  size: 20, 
                  color: isDark ? const Color(0xFF00E5FF) : colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
