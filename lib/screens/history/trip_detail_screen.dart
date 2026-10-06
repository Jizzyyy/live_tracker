import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/tracker_models.dart';
import '../../models/trip_history_model.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/gpx_exporter.dart';
import '../../utils/geojson_exporter.dart';
import '../../utils/kml_exporter.dart';
import '../../utils/csv_exporter.dart';
import '../../controllers/route_playback_controller.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/map_bounds_helper.dart';
import '../../widgets/trip_share_card.dart';
import '../../widgets/elevation_chart.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final CompletedTrip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  MapStyleOption _selectedMapStyle = availableMapStyles.first;
  bool _isExporting = false;
  late CompletedTrip _currentTrip;
  late final RoutePlaybackController _playbackController;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _playbackController = RoutePlaybackController(trip: widget.trip);
  }

  @override
  void dispose() {
    _playbackController.dispose();
    super.dispose();
  }

  Future<void> _handleRenameTrip() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: _currentTrip.customTitle ?? '');

    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF12151B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ubah Nama Rute',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0D1117)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Misal: Touring Puncak, Morning Ride...',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );

    if (newTitle == null || !mounted) return;

    final updated = _currentTrip.copyWith(customTitle: () => newTitle.isNotEmpty ? newTitle : null);
    await ref.read(tripHistoryProvider.notifier).saveTrip(updated);
    setState(() => _currentTrip = updated);

    if (mounted) {
      CustomSnackbar.show(context, message: 'Nama rute diperbarui!', type: SnackbarType.success);
    }
  }

  Future<void> _handleExport(String format) async {
    setState(() => _isExporting = true);
    try {
      if (format == 'gpx') {
        await GpxExporter.exportAndShare(widget.trip);
      } else if (format == 'geojson') {
        await GeoJsonExporter.exportAndShare(widget.trip);
      } else if (format == 'kml') {
        await KmlExporter.exportAndShare(widget.trip);
      } else if (format == 'csv') {
        await CsvExporter.exportAndShare(widget.trip);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, message: 'Gagal mengekspor ${format.toUpperCase()}: $e', type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _confirmDeleteTrip() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF12151B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus rute ini?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
        ),
        content: Text(
          'Rekaman rute ini akan dihapus secara permanen dari perangkat.',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF4A5568),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'BATAL',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await ref.read(tripHistoryProvider.notifier).deleteTrip(widget.trip.id);
    if (!mounted) return;

    CustomSnackbar.show(context, message: 'Rute berhasil dihapus', type: SnackbarType.info);
    Navigator.pop(context);
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
    final trip = _currentTrip;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = trip.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = calculateSafeBounds(points);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          trip.displayTitle, 
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF0D1117),
        ),
        actions: [
          // Rename Trip Action
          IconButton(
            tooltip: 'Ubah Nama',
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706),
              size: 20,
            ),
            onPressed: _handleRenameTrip,
          ),
          // Share Image Action (Card Exporter)
          IconButton(
            tooltip: 'Share Card',
            icon: Icon(
              Icons.photo_camera_back_outlined, 
              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
            ),
            onPressed: _showShareCardDialog,
          ),
          // Multi-Format GIS Export Action
          PopupMenuButton<String>(
            tooltip: 'Export GIS Data',
            enabled: !_isExporting,
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
            color: isDark ? const Color(0xFF1E232D) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: _handleExport,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'gpx',
                child: Row(
                  children: [
                    const Icon(Icons.route_outlined, size: 18, color: Color(0xFF00E676)),
                    const SizedBox(width: 10),
                    Text(
                      'Export GPX 1.1',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'geojson',
                child: Row(
                  children: [
                    const Icon(Icons.data_object_rounded, size: 18, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 10),
                    Text(
                      'Export GeoJSON (RFC 7946)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'kml',
                child: Row(
                  children: [
                    const Icon(Icons.public_rounded, size: 18, color: Color(0xFFFFD600)),
                    const SizedBox(width: 10),
                    Text(
                      'Export Google Earth (KML)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_rounded, size: 18, color: Color(0xFFFF9100)),
                    const SizedBox(width: 10),
                    Text(
                      'Export Telemetri (CSV)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Hapus Rute',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmDeleteTrip,
          ),
          const SizedBox(width: 4),
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
                        userAgentPackageName: 'VellumLiveTracker/1.0 (contact: kadhafiinl@github)',
                        keepBuffer: 2,
                        panBuffer: 1,
                        tileUpdateTransformer: TileUpdateTransformers.throttle(const Duration(milliseconds: 250)),
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
                      // Replay Vehicle Marker with Animated Rotation
                      ListenableBuilder(
                        listenable: _playbackController,
                        builder: (context, _) {
                          final pt = _playbackController.currentPoint;
                          if (pt == null) return const SizedBox.shrink();
                          final heading = _playbackController.currentHeading ?? 0.0;
                          return MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(pt.latitude, pt.longitude),
                                width: 44,
                                height: 44,
                                child: Transform.rotate(
                                  angle: heading * 3.1415926535 / 180.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12151B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFFFD600), width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.navigation_rounded,
                                      color: Color(0xFFFFD600),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
                        items: ref.watch(mapStyleListProvider).map((style) {
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

                // Live Replay Telemetry HUD Pill
                Positioned(
                  top: 12,
                  left: 12,
                  child: ListenableBuilder(
                    listenable: _playbackController,
                    builder: (context, _) {
                      final pt = _playbackController.currentPoint;
                      if (pt == null) return const SizedBox.shrink();

                      final spd = pt.speed != null ? '${pt.speed!.toStringAsFixed(1)} km/h' : '-- km/h';
                      final alt = pt.altitude != null ? '${pt.altitude!.toStringAsFixed(0)} m' : '-- m';
                      final firstTs = widget.trip.routePoints.isNotEmpty ? widget.trip.routePoints.first.timestamp : pt.timestamp;
                      final elapsedSecs = ((pt.timestamp - firstTs) / 1000).round();
                      final m = (elapsedSecs ~/ 60).toString().padLeft(2, '0');
                      final s = (elapsedSecs % 60).toString().padLeft(2, '0');

                      return PremiumGlass(
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.speed_rounded, size: 14, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 4),
                            Text(
                              spd,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.terrain_rounded, size: 14, color: Color(0xFF00E676)),
                            const SizedBox(width: 4),
                            Text(
                              alt,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$m:$s',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Interactive Route Playback Dock
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: ListenableBuilder(
                    listenable: _playbackController,
                    builder: (context, _) {
                      final isPlaying = _playbackController.isPlaying;
                      final progress = _playbackController.progress;
                      final speedLabel = '${_playbackController.playbackSpeed.toStringAsFixed(0)}x';

                      return PremiumGlass(
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                size: 32,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _playbackController.togglePlay();
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  activeTrackColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                                  thumbColor: isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706),
                                ),
                                child: Slider(
                                  value: progress.clamp(0.0, 1.0),
                                  onChanged: (val) {
                                    _playbackController.seekToFraction(val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _playbackController.cycleSpeed();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E232D) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                  ),
                                ),
                                child: Text(
                                  speedLabel,
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                            label: 'TOTAL DURATION', 
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
                            label: 'MOVING TIME', 
                            value: trip.formattedMovingDuration, 
                            color: isDark ? const Color(0xFF00E676) : const Color(0xFF059669),
                          ),
                        ),
                        Expanded(
                          child: _TelemetryTile(
                            label: 'STOPPED TIME', 
                            value: trip.formattedStoppedDuration, 
                            color: isDark ? const Color(0xFFFF9100) : const Color(0xFFD97706),
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
                            label: 'MAX GRADIENT', 
                            value: trip.formattedMaxGradient, 
                            color: isDark ? const Color(0xFFFF5252) : const Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                    const SizedBox(height: 16),
                    ListenableBuilder(
                      listenable: _playbackController,
                      builder: (context, _) {
                        return ElevationChart(
                          trip: trip,
                          isDark: isDark,
                          externalCursorFraction: _playbackController.progress,
                        );
                      },
                    ),
                    if (trip.splits.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                      const SizedBox(height: 16),
                      _SplitsTable(splits: trip.splits, isDark: isDark),
                    ],
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

class _SplitsTable extends StatelessWidget {
  final List<TripSplit> splits;
  final bool isDark;

  const _SplitsTable({required this.splits, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KILOMETER SPLITS',
              style: GoogleFonts.shareTechMono(
                fontSize: 11,
                letterSpacing: 2,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${splits.length} KM',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('KM', style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.grey))),
                    Expanded(flex: 3, child: Text('PACE', style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.grey))),
                    Expanded(flex: 3, child: Text('ELEVASI', style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.grey))),
                    Expanded(flex: 3, child: Text('KECEPATAN', textAlign: TextAlign.right, style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.grey))),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
              ...splits.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${s.kilometer}',
                        style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        s.formattedPace,
                        style: GoogleFonts.jetBrainsMono(fontSize: 12, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        s.formattedElevation,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: s.elevationChangeMeters >= 0 ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${s.avgSpeedKmh.toStringAsFixed(1)} km/h',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.jetBrainsMono(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
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
