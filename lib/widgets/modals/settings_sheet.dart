import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    
    return PremiumGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Settings', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: settings.isDarkMode,
              onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(isDarkMode: val)),
            ),
            SwitchListTile(
              title: const Text('High Accuracy GPS'),
              value: settings.highAccuracyGps,
              onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(highAccuracyGps: val)),
            ),
            SwitchListTile(
              title: const Text('Background Service'),
              value: settings.backgroundService,
              onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(backgroundService: val)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
