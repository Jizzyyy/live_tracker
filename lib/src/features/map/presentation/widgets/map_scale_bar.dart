import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScaleBar extends StatelessWidget {
  const MapScaleBar({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100, // Di atas FAB dan LocationInfoCard
      left: 16,
      child: StreamBuilder<MapEvent>(
        stream: mapController.mapEventStream,
        builder: (context, snapshot) {
          final camera = mapController.camera;
          
          try {
            final bounds = camera.visibleBounds;
            // Validate bounds manually to prevent NaN crashes
            if (bounds.southWest.latitude.isNaN || bounds.southWest.longitude.isNaN) {
              return const SizedBox.shrink();
            }

            final distanceCalculator = const Distance();
            final distanceMeters = distanceCalculator.as(
              LengthUnit.Meter,
              bounds.southWest,
              bounds.southEast,
            );

            String label;
            double width;
            
            if (distanceMeters > 10000) { // > 10km
              label = '${(distanceMeters / 4000).round()} km';
              width = 80;
            } else if (distanceMeters > 1000) { // > 1km
              label = '1 km';
              width = 80 / (distanceMeters / 1000);
            } else {
              label = '${(distanceMeters / 4).round()} m';
              width = 80;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                  ),
                ),
                Container(
                  width: width.clamp(40.0, 150.0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ],
            );
          } catch (e) {
            // map bounds might not be fully initialized yet
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
