import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tracker_models.dart';
import '../utils/app_theme.dart';
import '../utils/geo_bearing_helper.dart';

class CustomUserMarker extends StatefulWidget {
  final MemberLocation location;
  final Color color;
  final bool isLocalUser;
  
  const CustomUserMarker({
    super.key, 
    required this.location,
    required this.color,
    this.isLocalUser = false,
  });

  @override
  State<CustomUserMarker> createState() => _CustomUserMarkerState();
}

class _CustomUserMarkerState extends State<CustomUserMarker> with SingleTickerProviderStateMixin {
  AnimationController? _haloCtrl;
  double _currentTurns = 0.0;
  bool _hasInitialTurns = false;

  @override
  void initState() {
    super.initState();
    _updateHalo();
    final initialHeading = widget.location.heading;
    if (initialHeading != null) {
      _currentTurns = initialHeading / 360.0;
      _hasInitialTurns = true;
    }
  }

  @override
  void didUpdateWidget(CustomUserMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.speedKmh != widget.location.speedKmh) {
      _updateHalo();
    }
    if (oldWidget.location.heading != widget.location.heading && widget.location.heading != null) {
      _updateHeading(widget.location.heading!);
    }
  }

  void _updateHeading(double targetDeg) {
    if (!_hasInitialTurns) {
      _currentTurns = targetDeg / 360.0;
      _hasInitialTurns = true;
      return;
    }
    final currentDeg = _currentTurns * 360.0;
    final delta = GeoBearingHelper.calculateShortestAngleDelta(currentDeg, targetDeg);
    _currentTurns = (currentDeg + delta) / 360.0;
  }

  void _updateHalo() {
    final speed = widget.location.speedKmh ?? 0.0;
    // Activate pulse glow animation ONLY if moving significantly faster than walking speed (> 8 km/h)
    if (speed > 8.0) {
      if (_haloCtrl == null) {
        _haloCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
        _haloCtrl!.repeat(reverse: true);
      }
    } else if (_haloCtrl != null) {
      _haloCtrl!.stop();
      _haloCtrl!.dispose();
      _haloCtrl = null;
    }
  }

  @override
  void dispose() {
    _haloCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStale = !widget.isLocalUser && widget.location.isStale;
    final isIdle = widget.location.isIdle || isStale;
    final displayName = (widget.location.name != null && widget.location.name!.trim().isNotEmpty)
        ? widget.location.name!.trim()
        : (widget.isLocalUser ? 'YOU' : 'User ${widget.location.id}');
    final effectiveColor = isStale ? Colors.grey : widget.color;
    final iconData = widget.isLocalUser ? Icons.person_pin_circle_rounded : Icons.person_rounded;

    Widget buildRotatingRing(double haloIntensity) {
      return Opacity(
        opacity: isStale ? 0.45 : 1.0,
        child: CustomPaint(
          size: const Size(56, 56),
          painter: _RingAndChevronPainter(
            color: effectiveColor,
            haloIntensity: isStale ? 0.0 : haloIntensity,
            isIdle: isIdle,
          ),
        ),
      );
    }

    // RepaintBoundary ensures isolated repaint during marker movement
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Rotating Navigation Ring & Directional Arrow
          AnimatedRotation(
            turns: _currentTurns,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _haloCtrl != null
                ? AnimatedBuilder(
                    animation: _haloCtrl!,
                    builder: (context, _) => buildRotatingRing(_haloCtrl!.value),
                  )
                : buildRotatingRing(0.0),
          ),

          // 2. Center Avatar Icon (Stays upright regardless of vehicle heading)
          Opacity(
            opacity: isStale ? 0.45 : 1.0,
            child: Icon(
              iconData,
              size: 22,
              color: isIdle ? Colors.white.withValues(alpha: 0.5) : effectiveColor,
            ),
          ),

          // 3. Upright Callsign Badge Chip
          Positioned(
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isStale ? Colors.grey : widget.color.withValues(alpha: 0.75),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4),
                ],
              ),
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: isStale ? Colors.grey : Colors.white,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingAndChevronPainter extends CustomPainter {
  final Color color;
  final double haloIntensity;
  final bool isIdle;

  _RingAndChevronPainter({
    required this.color,
    required this.haloIntensity,
    required this.isIdle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final coreRadius = size.width * 0.35;

    // 1. Glowing Halo Effect (when moving at speed)
    if (haloIntensity > 0) {
      final haloRadius = coreRadius + (size.width * 0.15 * haloIntensity);
      canvas.drawCircle(
        center,
        haloRadius,
        Paint()
          ..color = color.withValues(alpha: 0.3 * haloIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // 2. Base Circular Avatar Body (Obsidian Dark)
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = const Color(0xFF12151B)
        ..style = PaintingStyle.fill,
    );

    // 3. Neon Border Ring
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4. Directional Navigation Arrowhead (Prominent sharp chevron pointing North)
    final tipY = cy - coreRadius - 9;
    final baseY = cy - coreRadius + 2;
    final path = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx + 7, baseY)
      ..lineTo(cx, baseY - 3) // Aerodynamic inner notch like Google Maps
      ..lineTo(cx - 7, baseY)
      ..close();
      
    canvas.drawPath(
      path, 
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5),
    );
  }

  @override
  bool shouldRepaint(_RingAndChevronPainter old) => 
    old.color != color || 
    old.haloIntensity != haloIntensity || 
    old.isIdle != isIdle;
}
