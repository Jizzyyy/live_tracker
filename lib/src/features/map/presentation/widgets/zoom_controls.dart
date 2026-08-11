import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(
          icon: Icons.add,
          colorScheme: colorScheme,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          onPressed: () {
            final zoom = mapController.camera.zoom + 1;
            mapController.move(mapController.camera.center, zoom);
          },
        ),
        Container(height: 1, width: 40, color: colorScheme.outlineVariant),
        _ZoomButton(
          icon: Icons.remove,
          colorScheme: colorScheme,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          onPressed: () {
            final zoom = mapController.camera.zoom - 1;
            mapController.move(mapController.camera.center, zoom);
          },
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.colorScheme,
    required this.borderRadius,
    required this.onPressed,
  });

  final IconData icon;
  final ColorScheme colorScheme;
  final BorderRadius borderRadius;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface,
      borderRadius: borderRadius,
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
