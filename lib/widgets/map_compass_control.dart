import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../utils/ui_helpers.dart';

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

        return PremiumGlass(
          borderRadius: BorderRadius.circular(20),
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
