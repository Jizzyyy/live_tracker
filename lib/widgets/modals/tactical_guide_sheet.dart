import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/app_theme.dart';
import '../../providers/tracker_providers.dart';

class TacticalGuideSheet extends ConsumerWidget {
  const TacticalGuideSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = ref.watch(appStringsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: PremiumGlass(
          borderRadius: AppTheme.borderRadiusSheet,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tacticalGuideTitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                        Text(
                          s.tacticalGuideSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 14),

              // Guide Sections List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _GuideCard(
                      icon: Icons.radar_rounded,
                      iconColor: AppTheme.primaryCyan,
                      title: '1. Radar Peta & Auto-Follow',
                      description:
                          'Kamera otomatis mengikuti posisi GPS Anda secara real-time. Jika Anda menggeser peta manual, ketuk pill "Ikuti Lokasi" atau tombol auto-center di pojok kanan bawah untuk mengunci kembali ke pusat.',
                      isDark: isDark,
                    ),
                    _GuideCard(
                      icon: Icons.groups_rounded,
                      iconColor: AppTheme.warningAmber,
                      title: '2. Identitas & Pelacakan Kelompok',
                      description:
                          'Atur Nama Panggilan / Callsign Anda di menu Pengaturan. Peta secara otomatis menampilkan posisi GPS real-time, heading arah, tingkat baterai, dan jarak relatif seluruh rekan konvoi secara presisi.',
                      isDark: isDark,
                    ),
                    _GuideCard(
                      icon: Icons.campaign_rounded,
                      iconColor: AppTheme.primaryCyan,
                      title: '3. Quick Pings & Obrolan Taktis',
                      description:
                          'Saat berkendara tanpa sempat mengetik, gunakan tombol Megafon untuk menyiarkan instruksi instan 1-ketuk (Regroup, Bahaya, Bensin, Belok, Istirahat) dengan nada akustik khusus. Gunakan Room Chat untuk koordinasi pesan teks antar anggota.',
                      isDark: isDark,
                    ),
                    _GuideCard(
                      icon: Icons.sos_rounded,
                      iconColor: AppTheme.dangerRed,
                      title: '4. Keselamatan SOS & Geofence Bahaya',
                      description:
                          '• Tombol SOS di menu Pengaturan menyiarkan sirene akustik dan banner darurat ke seluruh anggota room saat terjadi kendala.\n'
                          '• Watchdog Bahaya: Jika ada anggota yang menandai titik bahaya (lubang, longsor, licin), aplikasi akan membunyikan alarm otomatis saat Anda mendekati radius 150 meter.\n'
                          '• Watchdog Pemisahan: Memberi peringatan jika Anda terpisah > 500m dari rekan terdekat.',
                      isDark: isDark,
                    ),
                    _GuideCard(
                      icon: Icons.undo_rounded,
                      iconColor: AppTheme.accentOrange,
                      title: '5. Navigasi Pulang (Backtracking)',
                      description:
                          'Kehilangan arah di pedalaman atau jalan hutan? Aktifkan tombol Backtrack di header untuk membalikkan jejak rekam GPS Anda menjadi rute pulang menuju titik awal, lengkap dengan deteksi deviasi keluar jalur (Off-Trail > 80m).',
                      isDark: isDark,
                    ),
                    _GuideCard(
                      icon: Icons.battery_charging_full_rounded,
                      iconColor: AppTheme.secondaryGreen,
                      title: '6. Smart Auto-Pause & Battery Guard',
                      description:
                          '• Smart Auto-Pause: Otomatis membekukan penghitung durasi saat berhenti di lampu merah atau istirahat agar kecepatan rata-rata tidak terdistorsi.\n'
                          '• Smart Battery Guard: Otomatis beralih ke Mode Hemat Data (interval GPS 5s) saat baterai perangkat turun di bawah 20%.\n'
                          '• Offline Queue: Hingga 50 paket koordinat otomatis disimpan saat sinyal seluler putus dan dikirim seketika saat terhubung kembali.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                s.iUnderstand,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isDark;

  const _GuideCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.45,
                    color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
