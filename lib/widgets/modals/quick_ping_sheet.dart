import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/tracker_models.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/sound_manager.dart';
import '../../utils/custom_snackbar.dart';

class QuickPingSelectorSheet extends ConsumerWidget {
  const QuickPingSelectorSheet({super.key});

  static const _cueConfigs = [
    (
      cue: TacticalCueType.regroup,
      title: 'Regroup / Kumpul',
      subtitle: 'Minta rekan memperlambat & berkumpul',
      icon: Icons.groups_rounded,
      color: Color(0xFF00E5FF),
    ),
    (
      cue: TacticalCueType.hazard,
      title: 'Bahaya di Depan',
      subtitle: 'Peringatan lubang, jalan licin, atau rintangan',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFF1744),
    ),
    (
      cue: TacticalCueType.fuel,
      title: 'Isi Bensin / SPBU',
      subtitle: 'Butuh isi bahan bakar di SPBU terdekat',
      icon: Icons.local_gas_station_rounded,
      color: Color(0xFFFFD600),
    ),
    (
      cue: TacticalCueType.turnLeft,
      title: 'Siap Belok Kiri',
      subtitle: 'Instruksi navigasi belok kiri di persimpangan',
      icon: Icons.turn_left_rounded,
      color: Color(0xFF69F0AE),
    ),
    (
      cue: TacticalCueType.turnRight,
      title: 'Siap Belok Kanan',
      subtitle: 'Instruksi navigasi belok kanan di persimpangan',
      icon: Icons.turn_right_rounded,
      color: Color(0xFF69F0AE),
    ),
    (
      cue: TacticalCueType.rest,
      title: 'Istirahat / Coffee Stop',
      subtitle: 'Usulan menepi sejenak untuk istirahat',
      icon: Icons.coffee_rounded,
      color: Color(0xFFFF9100),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inRoom = ref.watch(roomProvider.select((r) => r.roomCode != null));

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFF00E5FF), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TACTICAL QUICK PINGS',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                        Text(
                          inRoom
                              ? 'Kirim instruksi taktis instan ke seluruh konvoi'
                              : 'Masuk room konvoi untuk menyiarkan pesan ke rekan',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...List.generate(_cueConfigs.length, (index) {
                final item = _cueConfigs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      final myPos = ref.read(locationStreamProvider).valueOrNull;
                      final settings = ref.read(appSettingsProvider);

                      ref.read(roomProvider.notifier).sendTacticalPing(
                        item.cue,
                        lat: myPos?.latitude,
                        lng: myPos?.longitude,
                      );

                      SoundManager.playTacticalCue(
                        item.cue,
                        soundEnabled: settings.soundAlertsEnabled,
                        hapticEnabled: settings.hapticAlertsEnabled,
                      );

                      Navigator.pop(context);

                      CustomSnackbar.show(
                        context,
                        message: inRoom
                            ? 'Pesan taktis "${item.title}" disiarkan ke konvoi!'
                            : 'Pesan taktis "${item.title}" diaktifkan (Mode Solo).',
                        type: SnackbarType.success,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.color.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: item.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.send_rounded,
                            color: item.color.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
