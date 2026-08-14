import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

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
        // Hanya tampil jika peta sedang di-rotasi (tidak utara)
        if (rotation == 0.0) return const SizedBox.shrink();

        return Positioned(
          top: 100, // Di bawah TripStatsCard
          right: 16,
          child: Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            child: InkWell(
              onTap: () {
                // Reset rotasi ke utara (0 derajat)
                mapController.rotate(0.0);
              },
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Transform.rotate(
                  // Putar ikon berlawanan arah rotasi peta
                  angle: -rotation * (3.1415926535897932 / 180),
                  child: Icon(
                    Icons.navigation,
                    size: 20,
                    color: colorScheme.error, // Merah untuk jarum kompas
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
