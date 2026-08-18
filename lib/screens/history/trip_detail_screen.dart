import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/tracker_models.dart';
import '../../models/trip_history_model.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/gpx_exporter.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/custom_snackbar.dart';
import '../../widgets/trip_share_card.dart';

class TripDetailScreen extends StatefulWidget {
  final CompletedTrip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  MapStyleOption _selectedMapStyle = availableMapStyles.first;
  bool _isExporting = false;

  Future<void> _handleGpxExport() async {
    setState(() => _isExporting = true);
    try {
      await GpxExporter.exportAndShare(widget.trip);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, message: 'Gagal mengekspor GPX: $e', type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showShareCardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TripShareCard(trip: widget.trip, boundaryKey: _shareCardKey),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('TUTUP'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      CustomSnackbar.show(context, message: 'Menyiapkan kartu rute...', type: SnackbarType.info);
                      await TripShareCard.captureAndShare(_shareCardKey, widget.trip);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('BAGIKAN GAMBAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final points = trip.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = points.isNotEmpty 
        ? LatLngBounds.fromPoints(points)
        : LatLngBounds(const LatLng(-6.2, 106.8), const LatLng(-6.2, 106.8));

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(trip.formattedDate, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Share Image Action (Strava-style card)
          IconButton(
            tooltip: 'Share Card',
            icon: const Icon(Icons.photo_camera_back_outlined, color: Color(0xFF00E5FF)),
            onPressed: _showShareCardDialog,
          ),
          // GPX Export Action
          IconButton(
            tooltip: 'Export GPX',
            icon: _isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)))
                : const Icon(Icons.ios_share_outlined, color: Color(0xFF00E676)),
            onPressed: _isExporting ? null : _handleGpxExport,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Map Canvas with Custom Style & Start/End Markers
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(48),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _selectedMapStyle.urlTemplate,
                        subdomains: _selectedMapStyle.subdomains,
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 4.5,
                            color: const Color(0xFF00E5FF),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          if (points.isNotEmpty)
                            Marker(
                              point: points.first,
                              width: 32, height: 32,
                              child: const Icon(Icons.flag_rounded, color: Color(0xFF00E676), size: 28),
                            ),
                          if (points.length > 1)
                            Marker(
                              point: points.last,
                              width: 32, height: 32,
                              child: const Icon(Icons.sports_score_rounded, color: Color(0xFFFF1744), size: 28),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Map Style Switcher Overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: PremiumGlass(
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MapStyleOption>(
                        value: _selectedMapStyle,
                        dropdownColor: const Color(0xFF12151B),
                        icon: const Icon(Icons.layers_outlined, color: Color(0xFF00E5FF), size: 18),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        items: availableMapStyles.map((style) {
                          return DropdownMenuItem(
                            value: style,
                            child: Text(style.name),
                          );
                        }).toList(),
                        onChanged: (newStyle) {
                          if (newStyle != null) setState(() => _selectedMapStyle = newStyle);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Telemetry Breakdown (Strava-grade)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PremiumGlass(
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TRIP METRICS',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          trip.formattedTimeRange,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _TelemetryTile(label: 'DISTANCE', value: trip.formattedDistance, color: const Color(0xFF00E676))),
                        Expanded(child: _TelemetryTile(label: 'DURATION', value: trip.formattedDuration, color: const Color(0xFFFFD600))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _TelemetryTile(label: 'AVG PACE', value: trip.formattedPace, color: const Color(0xFF00E5FF))),
                        Expanded(child: _TelemetryTile(label: 'AVG SPEED', value: trip.formattedAvgSpeed, color: const Color(0xFF38BDF8))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _TelemetryTile(label: 'TOP SPEED', value: trip.formattedMaxSpeed, color: const Color(0xFFFF1744))),
                        Expanded(child: _TelemetryTile(label: 'GPS BREADCRUMBS', value: '${trip.routePoints.length} pts', color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.shareTechMono(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
