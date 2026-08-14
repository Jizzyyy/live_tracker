import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white30 : Colors.black26, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Preferences', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              _SettingsTile(
                title: 'Dark Map Theme',
                subtitle: 'Use high-contrast dark map tiles',
                icon: Icons.dark_mode_outlined,
                value: settings.isDarkMode,
                onChanged: (val) {
                  ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(isDarkMode: val));
                  // Auto-switch map style based on preference
                  ref.read(mapStyleProvider.notifier).state = val ? availableMapStyles[0] : availableMapStyles[1];
                },
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                title: 'High Accuracy Tracking',
                subtitle: 'Consume more battery for precise routes',
                icon: Icons.gps_fixed,
                value: settings.highAccuracyGps,
                onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(highAccuracyGps: val)),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                title: 'Background Service',
                subtitle: 'Keep tracking when app is closed',
                icon: Icons.autorenew,
                value: settings.backgroundService,
                onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(backgroundService: val)),
              ),
              const SizedBox(height: 32),
              
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('DONE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({required this.title, required this.subtitle, required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
