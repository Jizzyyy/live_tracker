import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/tracker_models.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class PoiDetailSheet extends ConsumerWidget {
  final SharedPoi poi;

  const PoiDetailSheet({super.key, required this.poi});

  double _calculateBearing(LatLng start, LatLng dest) {
    final startLat = start.latitudeInRad;
    final startLng = start.longitudeInRad;
    final destLat = dest.latitudeInRad;
    final destLng = dest.longitudeInRad;

    final dLng = destLng - startLng;
    final y = sin(dLng) * cos(destLat);
    final x = cos(startLat) * sin(destLat) - sin(startLat) * cos(destLat) * cos(dLng);
    final initialBearing = atan2(y, x);
    return (initialBearing * 180 / pi + 360) % 360;
  }

  String _bearingToCardinal(double bearing) {
    const cardinals = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL', 'U'];
    return cardinals[((bearing + 22.5) % 360 ~/ 45)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final posAsync = ref.watch(locationStreamProvider);
    double? distMeters;
    double? bearingDeg;
    String? cardinal;
    String? etaStr;

    if (posAsync.hasValue) {
      final pos = posAsync.value!;
      final myPos = LatLng(pos.latitude, pos.longitude);
      final poiPos = LatLng(poi.latitude, poi.longitude);

      distMeters = const Distance().as(LengthUnit.Meter, myPos, poiPos);
      bearingDeg = _calculateBearing(myPos, poiPos);
      cardinal = _bearingToCardinal(bearingDeg);

      final speedKmh = pos.speed * 3.6;
      final effectiveSpeedMps = speedKmh > 5.0 ? pos.speed : (30.0 / 3.6); // default to 30km/h cruising pace
      if (effectiveSpeedMps > 0 && distMeters > 0) {
        final etaSeconds = (distMeters / effectiveSpeedMps).round();
        if (etaSeconds < 60) {
          etaStr = '< 1 mnt';
        } else {
          final m = etaSeconds ~/ 60;
          final h = m ~/ 60;
          final remM = m % 60;
          etaStr = h > 0 ? '$h jam $remM mnt' : '$m mnt';
        }
      }
    }

    final categoryConfig = switch (poi.category) {
      PoiCategory.rendezvous => (name: 'Titik Kumpul', icon: Icons.flag_rounded, color: const Color(0xFF00E5FF)),
      PoiCategory.fuel => (name: 'SPBU', icon: Icons.local_gas_station_rounded, color: const Color(0xFFFFD600)),
      PoiCategory.hazard => (name: 'Bahaya / Rintangan', icon: Icons.warning_amber_rounded, color: const Color(0xFFFF1744)),
      PoiCategory.rest => (name: 'Rest Area', icon: Icons.hotel_rounded, color: const Color(0xFF00E676)),
    };

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryConfig.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(categoryConfig.icon, color: categoryConfig.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.title,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kategori: ${categoryConfig.name} • Dibuat oleh ${poi.createdBy}',
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E232D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KOORDINAT',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          Text(
                            '${poi.latitude.toStringAsFixed(5)}, ${poi.longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (distMeters != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'JARAK',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                            Text(
                              distMeters < 1000
                                  ? '${distMeters.toStringAsFixed(0)} m'
                                  : '${(distMeters / 1000).toStringAsFixed(2)} km',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: categoryConfig.color,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (distMeters != null) ...[
                    const Divider(height: 16, color: Colors.white12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (bearingDeg != null && cardinal != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BEARING / ARAH',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.explore_outlined, size: 14, color: categoryConfig.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${bearingDeg.toStringAsFixed(0)}° $cardinal',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        if (etaStr != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ESTIMASI TIBA (ETA)',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF00E676)),
                                  const SizedBox(width: 4),
                                  Text(
                                    etaStr,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00E676),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF1744),
                  side: const BorderSide(color: Color(0xFFFF1744)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('HAPUS PIN TANDANGAN INI', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(roomProvider.notifier).deletePoi(poi.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
