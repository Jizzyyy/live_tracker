import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  AnimationController? _haloCtrl;

  @override
  void initState() {
    super.initState();
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
    // Activate pulse glow animation ONLY if moving significantly faster than walking speed (> 8 km/h)
    if (speed > 8.0) {
      if (_haloCtrl == null) {
        _haloCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
        _haloCtrl!.repeat(reverse: true);
        if (mounted) setState(() {});
      }
    } else {
      _haloCtrl?.stop();
      _haloCtrl?.dispose();
      _haloCtrl = null;
      if (mounted) setState(() {});
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
    final displayName = (widget.location.name != null && widget.location.name!.trim().isNotEmpty)
        ? widget.location.name!.trim()
        : (widget.isLocalUser ? 'YOU' : 'User ${widget.location.id}');

    final rolePrefix = widget.location.role != ConvoyRole.member
        ? '[${widget.location.role.badgeText}] '
        : '';
    final fullLabel = '$rolePrefix$displayName';

    final roleBorderColor = switch (widget.location.role) {
      ConvoyRole.leader => const Color(0xFFFFD700),
      ConvoyRole.sweeper => const Color(0xFF00E5FF),
      ConvoyRole.scout => const Color(0xFF76FF03),
      ConvoyRole.member => widget.color,
    };

    Widget buildMarker(double haloIntensity) {
      return Opacity(
        opacity: isStale ? 0.45 : 1.0,
        child: CustomPaint(
          size: const Size(56, 56),
          painter: _MarkerPainter(
            color: isStale ? Colors.grey : widget.color,
            haloIntensity: isStale ? 0.0 : haloIntensity,
            isIdle: widget.location.isIdle || isStale,
            isLocalUser: widget.isLocalUser,
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
          AnimatedRotation(
            turns: (widget.location.heading ?? 0) / 360.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _haloCtrl != null
                ? AnimatedBuilder(
                    animation: _haloCtrl!,
                    builder: (context, _) => buildMarker(_haloCtrl!.value),
                  )
                : buildMarker(0.0),
          ),
          Positioned(
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF12151B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isStale ? Colors.grey : roleBorderColor.withValues(alpha: 0.75),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4),
                ],
              ),
              child: Text(
                fullLabel,
                style: GoogleFonts.shareTechMono(
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
