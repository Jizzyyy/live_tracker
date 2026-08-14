import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/map_style_provider.dart';

class MapStyleSheet extends ConsumerWidget {
  const MapStyleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(mapStyleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gaya Peta',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...availableMapStyles.map((style) {
            final isSelected = style.name == currentStyle.name;

            return Card(
              elevation: isSelected ? 2 : 0,
              color: isSelected ? colorScheme.primaryContainer : null,
              child: ListTile(
                leading: Icon(
                  _iconForStyle(style.name),
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  style.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  style.attribution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(mapStyleProvider.notifier).state = style;
                  Navigator.of(context).pop();
                },
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _iconForStyle(String name) {
    return switch (name) {
      'Standard' => Icons.map_outlined,
      'Humanitarian' => Icons.volunteer_activism_outlined,
      'Light' => Icons.light_mode_outlined,
      'Dark' => Icons.dark_mode_outlined,
      _ => Icons.map,
    };
  }
}
