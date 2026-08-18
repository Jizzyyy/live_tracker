import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip_history_model.dart';

class TripShareCard extends StatelessWidget {
  final CompletedTrip trip;
  final GlobalKey boundaryKey;
  final bool isDark;

  const TripShareCard({
    super.key,
    required this.trip,
    required this.boundaryKey,
    this.isDark = true,
  });

  static Future<void> captureAndShare(GlobalKey key, CompletedTrip trip) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/live_tracker_${trip.id}.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'Live Tracker - ${trip.formattedDate}',
          text: 'Check out my route with Live Tracker! 🏃 ${trip.formattedDistance} in ${trip.formattedDuration}',
        ),
      );
    } catch (e) {
      debugPrint('Error capturing share card: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = trip.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = points.isNotEmpty 
        ? LatLngBounds.fromPoints(points) 
        : LatLngBounds(const LatLng(-6.2, 106.8), const LatLng(-6.2, 106.8));

    final bgColor = isDark ? const Color(0xFF0B0D11) : const Color(0xFFFFFFFF);
    final cardBorder = isDark ? Colors.white12 : Colors.black12;
    final textHeader = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    final mapTileUrl = isDark 
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    final polylineColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7);
    final footerBg = isDark ? const Color(0xFF12151B) : const Color(0xFFF1F5F9);
    final footerText = isDark ? Colors.white30 : const Color(0xFF94A3B8);

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with App Branding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.track_changes, 
                          color: polylineColor, 
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE TRACKER',
                        style: GoogleFonts.shareTechMono(
                          color: textHeader,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    trip.formattedDate,
                    style: GoogleFonts.inter(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Map Route Preview
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(32),
                    ),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapTileUrl,
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.livetracker.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4.0,
                          color: polylineColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'DISTANCE', 
                        value: trip.formattedDistance, 
                        color: isDark ? const Color(0xFF00E676) : const Color(0xFF059669),
                        isDark: isDark,
                      ),
                      _StatColumn(
                        label: 'DURATION', 
                        value: trip.formattedDuration, 
                        color: isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: dividerColor, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'AVG PACE', 
                        value: trip.formattedPace, 
                        color: polylineColor,
                        isDark: isDark,
                      ),
                      _StatColumn(
                        label: 'MAX SPEED', 
                        value: trip.formattedMaxSpeed, 
                        color: isDark ? const Color(0xFFFF1744) : const Color(0xFFDC2626),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer Watermark
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: footerBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(27)),
              ),
              child: Center(
                child: Text(
                  'CREATED BY KADHAFIINL',
                  style: GoogleFonts.shareTechMono(
                    fontSize: 9,
                    letterSpacing: 3,
                    color: footerText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatColumn({
    required this.label, 
    required this.value, 
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 10, 
            letterSpacing: 2, 
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
