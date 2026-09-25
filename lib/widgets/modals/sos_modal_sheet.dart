import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/sound_manager.dart';

class SosModalSheet extends ConsumerStatefulWidget {
  const SosModalSheet({super.key});

  @override
  ConsumerState<SosModalSheet> createState() => _SosModalSheetState();
}

class _SosModalSheetState extends ConsumerState<SosModalSheet> {
  final _noteController = TextEditingController();
  String _selectedPreset = '🚨 Butuh Bantuan Segera';

  static const _presets = [
    '🚨 Butuh Bantuan Segera',
    '⚠️ Kecelakaan / Jatuh',
    '🔧 Kerusakan Mesin / Ban Bocor',
    '⛽ Kehabisan Bahan Bakar',
    '🌧️ Terjebak Cuaca Buruk / Tersesat',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeSos = ref.watch(roomProvider.select((r) => r.activeSos));
    final inRoom = ref.watch(roomProvider.select((r) => r.roomCode != null));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                      color: const Color(0xFFFF1744).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sos_rounded, color: Color(0xFFFF1744), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY SOS BEACON',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: const Color(0xFFFF1744),
                          ),
                        ),
                        Text(
                          inRoom ? 'Siarkan sinyal darurat ke seluruh anggota room' : 'Siaran darurat mandiri / lokal',
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
              const SizedBox(height: 20),

              if (activeSos != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1744), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'SOS AKTIF: ${activeSos.userId}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF1744),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeSos.note,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00E676),
                      side: const BorderSide(color: Color(0xFF00E676)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('CABUT / MATIKAN SINYAL SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(roomProvider.notifier).dismissSos();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                'PILIH KATEGORI DARURAT',
                style: GoogleFonts.shareTechMono(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF1744).withValues(alpha: 0.25),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFFF1744) : (isDark ? Colors.white12 : Colors.black12),
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFFF1744) : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedPreset = preset);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Catatan tambahan opsional...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E232D) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.warning_rounded, size: 22),
                  label: Text(
                    'SIARKAN SINYAL SOS SEKARANG',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  onPressed: () {
                    SoundManager.playEmergencyAlarm();
                    final pos = ref.read(locationStreamProvider).valueOrNull;
                    final note = _noteController.text.trim().isNotEmpty
                        ? '$_selectedPreset - ${_noteController.text.trim()}'
                        : _selectedPreset;

                    ref.read(roomProvider.notifier).sendSosAlert(
                      note,
                      lat: pos?.latitude,
                      lng: pos?.longitude,
                    );

                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
