import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/tracker_models.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class MemberInspectionSheet extends ConsumerWidget {
  final MemberLocation member;

  const MemberInspectionSheet({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final myPos = ref.watch(locationStreamProvider).valueOrNull;
    double? distMeters;
    if (myPos != null) {
      distMeters = const Distance().as(
        LengthUnit.Meter,
        LatLng(myPos.latitude, myPos.longitude),
        LatLng(member.latitude, member.longitude),
      );
    }

    final secondsAgo = DateTime.now().difference(member.lastUpdated).inSeconds;
    final isStale = member.isStale;
    final displayName = (member.name != null && member.name!.trim().isNotEmpty)
        ? member.name!.trim()
        : 'User ${member.id}';

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? const Color(0xFF12151B) : colorScheme.primaryContainer,
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: isDark ? const Color(0xFF00E5FF) : colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isStale
                                  ? Colors.grey.withValues(alpha: 0.2)
                                  : const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isStale ? Colors.grey : const Color(0xFF00E676),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isStale ? 'STALE' : 'ONLINE',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 10,
                                    color: isStale ? Colors.grey : const Color(0xFF00E676),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${member.id} • Terakhir update ${secondsAgo}s lalu',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E232D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricItem(
                    label: 'JARAK',
                    value: distMeters != null
                        ? (distMeters < 1000 ? '${distMeters.toStringAsFixed(0)} m' : '${(distMeters / 1000).toStringAsFixed(2)} km')
                        : '--',
                    color: isDark ? const Color(0xFF00E5FF) : colorScheme.primary,
                  ),
                  _MetricItem(
                    label: 'KECEPATAN',
                    value: '${(member.speedKmh ?? 0).toStringAsFixed(1)} km/h',
                    color: const Color(0xFFFFD600),
                  ),
                  _MetricItem(
                    label: 'BATERAI',
                    value: member.batteryPercent != null ? '${member.batteryPercent}%' : '--',
                    color: (member.batteryPercent != null && member.batteryPercent! < 20)
                        ? const Color(0xFFFF1744)
                        : const Color(0xFF00E676),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF00E5FF) : colorScheme.primary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(focusedMemberProvider.notifier).state = member;
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.my_location_rounded, size: 20),
                label: const Text('FOKUSKAN KAMERA KE REKAN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(fontSize: 10, letterSpacing: 1.5, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
