import 'package:flutter/material.dart';
import '../models/tracker_models.dart';

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
  late final AnimationController _haloCtrl;

  @override
  void initState() {
    super.initState();
    _haloCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _updateHalo();
  }

  @override
  void didUpdateWidget(CustomUserMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.speedKmh != widget.location.speedKmh) {
      _updateHalo();
    }
  }

  void _updateHalo() {
    final speed = widget.location.speedKmh ?? 0.0;
    // Activate pulse glow only if moving faster than walking speed
    if (speed > 5.0 && !_haloCtrl.isAnimating) {
      _haloCtrl.repeat(reverse: true);
    } else if (speed <= 5.0 && _haloCtrl.isAnimating) {
      _haloCtrl.stop();
      _haloCtrl.value = 0.0;
    }
  }

  @override
  void dispose() {
    _haloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary ensures smooth 60fps rendering during rotation/pulsing
    return RepaintBoundary(
      child: AnimatedRotation(
        turns: (widget.location.heading ?? 0) / 360.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _haloCtrl,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(56, 56),
              painter: _MarkerPainter(
                color: widget.color,
                haloIntensity: _haloCtrl.value,
                isIdle: widget.location.isIdle,
                isLocalUser: widget.isLocalUser,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  final Color color;
  final double haloIntensity;
  final bool isIdle;
  final bool isLocalUser;

  _MarkerPainter({
    required this.color,
    required this.haloIntensity,
    required this.isIdle,
    required this.isLocalUser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final coreRadius = size.width * 0.35;

    // 1. Glowing Halo Effect (when moving)
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

    // 3. Neon Border
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4. Directional Chevron (Arrow pointing North relative to rotation)
    final path = Path()
      ..moveTo(cx, cy - coreRadius - 6)
      ..lineTo(cx + 6, cy - coreRadius + 2)
      ..lineTo(cx - 6, cy - coreRadius + 2)
      ..close();
      
    canvas.drawPath(
      path, 
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );

    // 5. Draw Person Icon (Replacing initial letters)
    final iconData = isLocalUser ? Icons.person_pin_circle_rounded : Icons.person_rounded;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        color: isIdle ? Colors.white.withValues(alpha: 0.5) : color,
        fontSize: 22,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => 
    old.color != color || 
    old.haloIntensity != haloIntensity || 
    old.isIdle != isIdle ||
    old.isLocalUser != isLocalUser;
}
