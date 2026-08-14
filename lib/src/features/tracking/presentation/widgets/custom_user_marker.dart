import 'package:flutter/material.dart';
import '../../../../core/models/tracking_models.dart';

class CustomUserMarker extends StatefulWidget {
  final MemberLocation location;
  final Color color;
  
  const CustomUserMarker({
    super.key, 
    required this.location,
    required this.color,
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
    if (speed > 25.0 && !_haloCtrl.isAnimating) {
      _haloCtrl.repeat(reverse: true);
    } else if (speed <= 25.0 && _haloCtrl.isAnimating) {
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
    // Ensure marker repaints independently of map
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
                initial: widget.location.id.substring(0, 1).toUpperCase(),
                haloIntensity: _haloCtrl.value,
                isIdle: widget.location.isIdle,
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
  final String initial;
  final double haloIntensity;
  final bool isIdle;

  _MarkerPainter({
    required this.color,
    required this.initial,
    required this.haloIntensity,
    required this.isIdle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final coreRadius = size.width * 0.35;

    // 1. Halo effect
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

    // 2. Base Circle
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = const Color(0xFF12151B)
        ..style = PaintingStyle.fill,
    );

    // 3. Border
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4. Directional Chevron (Top)
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

    // 5. Initial Text
    final textSpan = TextSpan(
      text: isIdle ? 'zZ' : initial,
      style: TextStyle(
        color: isIdle ? Colors.white.withValues(alpha: 0.5) : color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'JetBrainsMono',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
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
    old.isIdle != isIdle;
}
