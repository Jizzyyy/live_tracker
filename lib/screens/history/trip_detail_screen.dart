import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/trip_history_model.dart';
import '../../utils/ui_helpers.dart';

class TripDetailScreen extends StatelessWidget {
  final CompletedTrip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final points = trip.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

    // Calculate bounding box for auto-fit
    final bounds = LatLngBounds.fromPoints(points);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(trip.formattedDate, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Map with route polyline
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(48),
                  ),
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
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Start marker
                      if (points.isNotEmpty)
                        Marker(
                          point: points.first,
                          width: 32, height: 32,
                          child: const Icon(Icons.flag, color: Color(0xFF00E676), size: 28),
                        ),
                      // End marker
                      if (points.length > 1)
                        Marker(
                          point: points.last,
                          width: 32, height: 32,
                          child: const Icon(Icons.sports_score, color: Color(0xFFFF1744), size: 28),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Telemetry breakdown
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  PremiumGlass(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('TRIP SUMMARY', style: GoogleFonts.shareTechMono(fontSize: 12, letterSpacing: 3, color: Colors.grey)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _TelemetryTile(label: 'DISTANCE', value: trip.formattedDistance, color: const Color(0xFF00E676))),
                            Expanded(child: _TelemetryTile(label: 'DURATION', value: trip.formattedDuration, color: const Color(0xFFFFD600))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _TelemetryTile(label: 'AVG SPEED', value: trip.formattedAvgSpeed, color: const Color(0xFF00E5FF))),
                            Expanded(child: _TelemetryTile(label: 'MAX SPEED', value: trip.formattedMaxSpeed, color: const Color(0xFFFF1744))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _TelemetryTile(label: 'GPS POINTS', value: '${trip.routePoints.length}', color: Colors.white70)),
                            Expanded(child: _TelemetryTile(label: 'STARTED', value: '${trip.startTime.hour.toString().padLeft(2, '0')}:${trip.startTime.minute.toString().padLeft(2, '0')}', color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TelemetryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.shareTechMono(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.bold, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
