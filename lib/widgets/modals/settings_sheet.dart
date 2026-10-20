import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/tracker_models.dart';
import '../../providers/tracker_providers.dart';
import '../../src/core/services/websocket_service.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/app_theme.dart';
import 'tactical_guide_sheet.dart';
import 'sos_modal_sheet.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late final TextEditingController _userNameController;
  late final TextEditingController _urlController;
  late final TextEditingController _googleMapsApiKeyController;
  late final TextEditingController _cartoApiKeyController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: ref.read(appSettingsProvider).userName);
    _urlController = TextEditingController(text: ref.read(appSettingsProvider).serverUrl);
    _googleMapsApiKeyController = TextEditingController(text: ref.read(appSettingsProvider).googleMapsApiKey);
    _cartoApiKeyController = TextEditingController(text: ref.read(appSettingsProvider).cartoApiKey);
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _urlController.dispose();
    _googleMapsApiKeyController.dispose();
    _cartoApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final s = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, 
            right: 24, 
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                Text(s.preferencesTitle, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                TextField(
                  controller: _userNameController,
                  decoration: InputDecoration(
                    labelText: s.callsignLabel,
                    hintText: s.callsignHint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: s.saveCallsignTooltip,
                      onPressed: () {
                        final name = _userNameController.text.trim();
                        ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(userName: name));
                        FocusScope.of(context).unfocus();
                        CustomSnackbar.show(
                          context,
                          message: name.isNotEmpty ? s.callsignSaved(name) : s.callsignDisabled,
                          type: SnackbarType.success,
                        );
                      },
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Language Selector
                Text(
                  s.appLanguageLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: AppLanguage.values.map((lang) {
                    final isSelected = settings.language == lang;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Text(lang.flag),
                        label: Text(lang.label),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryCyan,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(language: lang));
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'WebSocket Server URL',
                    hintText: 'ws://192.168.x.x:8080',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                    suffixIcon: _isTesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.sync_rounded),
                            tooltip: s.testAndConnectTooltip,
                            onPressed: () async {
                              final url = _urlController.text.trim();
                              if (url.isNotEmpty) {
                                setState(() => _isTesting = true);
                                CustomSnackbar.show(context, message: s.testingServer, type: SnackbarType.info);
                                
                                final isAlive = await WebSocketService.testConnection(url);
                                if (!mounted) return;
                                setState(() => _isTesting = false);

                                ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(serverUrl: url));
                                ref.read(roomProvider.notifier).reconnect();

                              if (context.mounted) {
                                FocusScope.of(context).unfocus();
                                if (isAlive) {
                                  CustomSnackbar.show(context, message: s.serverOnline, type: SnackbarType.success);
                                } else {
                                  CustomSnackbar.show(context, message: s.serverOffline, type: SnackbarType.warning);
                                }
                              }
                              }
                            },
                          ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _googleMapsApiKeyController,
                  decoration: InputDecoration(
                    labelText: 'Google Maps API Key',
                    hintText: 'AIzaSy...',
                    helperText: isDark ? 'Roadmap / Satellite / Terrain' : 'Roadmap / Satellite / Terrain',
                    helperMaxLines: 1,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: s.saveApiKeyTooltip,
                      onPressed: () {
                        final key = _googleMapsApiKeyController.text.trim();
                        ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(googleMapsApiKey: key));
                        FocusScope.of(context).unfocus();
                        CustomSnackbar.show(
                          context,
                          message: key.isNotEmpty ? s.googleMapsKeySaved : s.googleMapsKeyDisabled,
                          type: SnackbarType.success,
                        );
                      },
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _cartoApiKeyController,
                  decoration: InputDecoration(
                    labelText: 'CartoDB API Key',
                    hintText: 'carto_api_key_xxx...',
                    helperText: 'Default: Esri Dark Canvas (Watermark-free)',
                    helperMaxLines: 1,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: s.saveApiKeyTooltip,
                      onPressed: () {
                        final key = _cartoApiKeyController.text.trim();
                        ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(cartoApiKey: key));
                        FocusScope.of(context).unfocus();
                        CustomSnackbar.show(
                          context,
                          message: key.isNotEmpty ? s.cartoKeySaved : s.cartoKeyDisabled,
                          type: SnackbarType.success,
                        );
                      },
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 16),
                
                _SettingsTile(
                  title: s.darkMapThemeTitle,
                  subtitle: s.darkMapThemeSubtitle,
                  icon: Icons.dark_mode_outlined,
                  value: settings.isDarkMode,
                  onChanged: (val) {
                    ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(isDarkMode: val));
                    ref.read(mapStyleProvider.notifier).state = val ? availableMapStyles[0] : availableMapStyles[1];
                  },
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: s.highAccuracyTitle,
                  subtitle: s.highAccuracySubtitle,
                  icon: Icons.gps_fixed,
                  value: settings.highAccuracyGps,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(highAccuracyGps: val)),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: s.backgroundServiceTitle,
                  subtitle: s.backgroundServiceSubtitle,
                  icon: Icons.autorenew,
                  value: settings.backgroundService,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(backgroundService: val)),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: s.soundAlertsTitle,
                  subtitle: s.soundAlertsSubtitle,
                  icon: Icons.volume_up_outlined,
                  value: settings.soundAlertsEnabled,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(soundAlertsEnabled: val)),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: s.hapticAlertsTitle,
                  subtitle: s.hapticAlertsSubtitle,
                  icon: Icons.vibration_rounded,
                  value: settings.hapticAlertsEnabled,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(hapticAlertsEnabled: val)),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: s.smartAutoPauseTitle,
                  subtitle: s.smartAutoPauseSubtitle,
                  icon: Icons.pause_circle_outline_rounded,
                  value: settings.smartAutoPause,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(smartAutoPause: val)),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: s.lowBandwidthTitle,
                  subtitle: s.lowBandwidthSubtitle,
                  icon: Icons.cell_tower_rounded,
                  value: settings.lowBandwidthMode,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(lowBandwidthMode: val)),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: s.hazardWatchdogTitle,
                  subtitle: s.hazardWatchdogSubtitle,
                  icon: Icons.warning_amber_rounded,
                  value: settings.hazardProximityAlert,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(hazardProximityAlert: val)),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.sos_rounded, size: 22),
                  label: Text(
                    s.broadcastSosButton,
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const SosModalSheet(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: AppTheme.primaryCyan.withValues(alpha: 0.5)),
                    foregroundColor: isDark ? AppTheme.primaryCyan : Theme.of(context).colorScheme.primary,
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(s.openTacticalGuide, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const TacticalGuideSheet(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.done, style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
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
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
