import 'package:flutter/material.dart';

class PulsingGlowMarker extends StatefulWidget {
  final Color color;

  const PulsingGlowMarker({
    super.key,
    this.color = const Color(0xFF00E5FF),
  });

  @override
  State<PulsingGlowMarker> createState() => _PulsingGlowMarkerState();
}

class _PulsingGlowMarkerState extends State<PulsingGlowMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(48, 48),
            painter: _GlowPainter(
              color: widget.color,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Color color;
  final double progress;

  _GlowPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coreRadius = size.width * 0.15;
    
    // Expanding pulse ring
    final pulseRadius = coreRadius + (size.width * 0.35 * progress);
    final pulseAlpha = (1.0 - progress) * 0.6;
    
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Static glow halo
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
    canvas.drawCircle(center, coreRadius * 2, haloPaint);

    // Solid core dot
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, coreRadius, corePaint);

    // Specular highlight
    final highlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(
      center + Offset(-coreRadius * 0.3, -coreRadius * 0.3),
      coreRadius * 0.3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
