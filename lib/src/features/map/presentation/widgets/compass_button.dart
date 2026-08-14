import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../shared/widgets/cyber_glass.dart';

class CompassButton extends StatelessWidget {
  const CompassButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapEvent>(
      stream: mapController.mapEventStream,
      builder: (context, snapshot) {
        final rotation = mapController.camera.rotation;
        if (rotation == 0.0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => mapController.rotate(0.0),
          child: SizedBox(
            width: 36,
            height: 36,
            child: CyberGlassPanel(
              borderRadius: 18.0,
              padding: EdgeInsets.zero,
              child: Center(
                child: AnimatedRotation(
                  turns: -rotation / 360.0,
                  duration: const Duration(milliseconds: 100),
                  child: const Icon(
                    Icons.navigation,
                    size: 20,
                    color: Color(0xFF00E5FF),
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
