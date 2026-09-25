import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip_history_model.dart';

class ElevationChart extends StatefulWidget {
  final CompletedTrip trip;
  final bool isDark;

  const ElevationChart({
    super.key,
    required this.trip,
    required this.isDark,
  });

  @override
  State<ElevationChart> createState() => _ElevationChartState();
}

class _ElevationChartState extends State<ElevationChart> {
  double? _selectedXFraction;

  @override
  Widget build(BuildContext context) {
    final pointsWithAlt = widget.trip.routePoints.where((p) => p.altitude != null).toList();

    if (pointsWithAlt.length < 2) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          'Data profil elevasi tidak tersedia untuk rute ini',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: widget.isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      );
    }

    final altitudes = pointsWithAlt.map((p) => p.altitude!).toList();
    final minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final maxAlt = altitudes.reduce((a, b) => a > b ? a : b);

    // Selected point inspection
    int? selectedIndex;
    double? selectedAlt;
    if (_selectedXFraction != null) {
      selectedIndex = (_selectedXFraction! * (altitudes.length - 1)).round().clamp(0, altitudes.length - 1);
      selectedAlt = altitudes[selectedIndex];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ELEVATION PROFILE',
              style: GoogleFonts.shareTechMono(
                fontSize: 11,
                letterSpacing: 2,
                color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (selectedAlt != null)
              Text(
                'ALT: ${selectedAlt.toStringAsFixed(1)} m',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                ),
              )
            else
              Text(
                '${widget.trip.formattedMinAltitude} / ${widget.trip.formattedMaxAltitude}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: widget.isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Chart Area with Gesture Detection
        SizedBox(
          height: 110,
          width: double.infinity,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localX = details.localPosition.dx;
                setState(() {
                  _selectedXFraction = (localX / box.size.width).clamp(0.0, 1.0);
                });
              }
            },
            onHorizontalDragEnd: (_) {
              setState(() => _selectedXFraction = null);
            },
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localX = details.localPosition.dx;
                setState(() {
                  _selectedXFraction = (localX / box.size.width).clamp(0.0, 1.0);
                });
              }
            },
            onTapUp: (_) {
              setState(() => _selectedXFraction = null);
            },
            child: CustomPaint(
              painter: _ElevationChartPainter(
                altitudes: altitudes,
                minAlt: minAlt,
                maxAlt: maxAlt,
                isDark: widget.isDark,
                selectedFraction: _selectedXFraction,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Elevation Gain & Loss Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Badge(
              icon: Icons.trending_up_rounded,
              label: 'GAIN',
              value: widget.trip.formattedElevationGain,
              color: const Color(0xFF00E676),
              isDark: widget.isDark,
            ),
            _Badge(
              icon: Icons.trending_down_rounded,
              label: 'LOSS',
              value: widget.trip.formattedElevationLoss,
              color: const Color(0xFFFF5252),
              isDark: widget.isDark,
            ),
            _Badge(
              icon: Icons.vertical_align_bottom_rounded,
              label: 'MIN',
              value: widget.trip.formattedMinAltitude,
              color: const Color(0xFF00E5FF),
              isDark: widget.isDark,
            ),
            _Badge(
              icon: Icons.vertical_align_top_rounded,
              label: 'MAX',
              value: widget.trip.formattedMaxAltitude,
              color: const Color(0xFFFFD600),
              isDark: widget.isDark,
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _Badge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.shareTechMono(
                fontSize: 9,
                letterSpacing: 1.5,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ElevationChartPainter extends CustomPainter {
  final List<double> altitudes;
  final double minAlt;
  final double maxAlt;
  final bool isDark;
  final double? selectedFraction;

  _ElevationChartPainter({
    required this.altitudes,
    required this.minAlt,
    required this.maxAlt,
    required this.isDark,
    this.selectedFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (altitudes.isEmpty) return;

    final range = (maxAlt - minAlt).abs() < 1.0 ? 1.0 : (maxAlt - minAlt);
    final width = size.width;
    final height = size.height;

    final linePath = Path();
    final fillPath = Path();

    final stepX = width / (altitudes.length - 1);

    for (int i = 0; i < altitudes.length; i++) {
      final x = i * stepX;
      // Invert Y: higher altitude is higher on canvas (smaller y)
      // Leave 10px padding top and bottom
      final normalizedAlt = (altitudes[i] - minAlt) / range;
      final y = height - 10 - (normalizedAlt * (height - 20));

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF00E5FF).withValues(alpha: 0.35),
              const Color(0xFF00E5FF).withValues(alpha: 0.0),
            ]
          : [
              const Color(0xFF0284C7).withValues(alpha: 0.25),
              const Color(0xFF0284C7).withValues(alpha: 0.0),
            ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Scrubber vertical indicator
    if (selectedFraction != null) {
      final scrubX = selectedFraction! * width;
      final index = (selectedFraction! * (altitudes.length - 1)).round().clamp(0, altitudes.length - 1);
      final normalizedAlt = (altitudes[index] - minAlt) / range;
      final scrubY = height - 10 - (normalizedAlt * (height - 20));

      final guidePaint = Paint()
        ..color = isDark ? Colors.white60 : Colors.black45
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(scrubX, 0), Offset(scrubX, height), guidePaint);

      final dotPaint = Paint()
        ..color = isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(scrubX, scrubY), 4.5, dotPaint);

      final dotRingPaint = Paint()
        ..color = isDark ? Colors.black : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(scrubX, scrubY), 4.5, dotRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationChartPainter oldDelegate) {
    return oldDelegate.selectedFraction != selectedFraction ||
        oldDelegate.altitudes != altitudes ||
        oldDelegate.isDark != isDark;
  }
}
