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
    bool cardIsDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme Toggle Bar for Share Card
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12151B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TEMA KARTU:',
                        style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('DARK'),
                        selected: cardIsDark,
                        selectedColor: const Color(0xFF00E5FF),
                        labelStyle: TextStyle(
                          color: cardIsDark ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        onSelected: (val) {
                          if (val) setDialogState(() => cardIsDark = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('LIGHT'),
                        selected: !cardIsDark,
                        selectedColor: const Color(0xFF00E5FF),
                        labelStyle: TextStyle(
                          color: !cardIsDark ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        onSelected: (val) {
                          if (val) setDialogState(() => cardIsDark = false);
                        },
                      ),
                    ],
                  ),
                ),

                // Card with selectable Theme (Dark/Light)
                TripShareCard(
                  trip: widget.trip, 
                  boundaryKey: _shareCardKey,
                  isDark: cardIsDark,
                ),
                const SizedBox(height: 16),
                
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = trip.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = points.isNotEmpty 
        ? LatLngBounds.fromPoints(points)
        : LatLngBounds(const LatLng(-6.2, 106.8), const LatLng(-6.2, 106.8));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          trip.formattedDate, 
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF0D1117),
        ),
        actions: [
          // Share Image Action (Card Exporter)
          IconButton(
            tooltip: 'Share Card',
            icon: Icon(
              Icons.photo_camera_back_outlined, 
              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
            ),
            onPressed: _showShareCardDialog,
          ),
          // GPX Export Action
          IconButton(
            tooltip: 'Export GPX',
            icon: _isExporting 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    ),
                  )
                : Icon(
                    Icons.ios_share_outlined, 
                    color: isDark ? const Color(0xFF00E676) : const Color(0xFF059669),
                  ),
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
                        userAgentPackageName: 'com.livetracker.app',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 4.5,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MapStyleOption>(
                        value: _selectedMapStyle,
                        dropdownColor: isDark ? const Color(0xFF12151B) : Colors.white,
                        icon: Icon(
                          Icons.layers_outlined, 
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), 
                          size: 18,
                        ),
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : const Color(0xFF0D1117), 
                          fontSize: 12, 
                          fontWeight: FontWeight.w600,
                        ),
                        items: availableMapStyles.map((style) {
                          return DropdownMenuItem(
                            value: style,
                            child: Text(
                              style.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0D1117),
                              ),
                            ),
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

          // Telemetry Breakdown
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
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          trip.formattedTimeRange,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TelemetryTile(
                            label: 'DISTANCE', 
                            value: trip.formattedDistance, 
                            color: isDark ? const Color(0xFF00E676) : const Color(0xFF059669),
                          ),
                        ),
                        Expanded(
                          child: _TelemetryTile(
                            label: 'DURATION', 
                            value: trip.formattedDuration, 
                            color: isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TelemetryTile(
                            label: 'AVG PACE', 
                            value: trip.formattedPace, 
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          ),
                        ),
                        Expanded(
                          child: _TelemetryTile(
                            label: 'AVG SPEED', 
                            value: trip.formattedAvgSpeed, 
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TelemetryTile(
                            label: 'TOP SPEED', 
                            value: trip.formattedMaxSpeed, 
                            color: isDark ? const Color(0xFFFF1744) : const Color(0xFFDC2626),
                          ),
                        ),
                        Expanded(
                          child: _TelemetryTile(
                            label: 'GPS BREADCRUMBS', 
                            value: '${trip.routePoints.length} pts', 
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: color,
          ),
        ),
      ],
    );
  }
}
