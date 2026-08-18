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

  const TripShareCard({
    super.key,
    required this.trip,
    required this.boundaryKey,
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

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0D11),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
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
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.track_changes, color: Color(0xFF00E5FF), size: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE TRACKER',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    trip.formattedDate,
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
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
                border: Border.all(color: Colors.white10),
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
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4.0,
                          color: const Color(0xFF00E5FF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats Grid (Strava-style)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'DISTANCE', value: trip.formattedDistance, color: const Color(0xFF00E676)),
                      _StatColumn(label: 'DURATION', value: trip.formattedDuration, color: const Color(0xFFFFD600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'AVG PACE', value: trip.formattedPace, color: const Color(0xFF00E5FF)),
                      _StatColumn(label: 'MAX SPEED', value: trip.formattedMaxSpeed, color: const Color(0xFFFF1744)),
                    ],
                  ),
                ],
              ),
            ),

            // Footer Watermark
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF12151B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(27)),
              ),
              child: Center(
                child: Text(
                  'FORGED BY KADHAFIINL',
                  style: GoogleFonts.shareTechMono(
                    fontSize: 9,
                    letterSpacing: 3,
                    color: Colors.white30,
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

  const _StatColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(fontSize: 10, letterSpacing: 2, color: Colors.grey),
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
