import 'dart:ui';
import 'package:flutter/material.dart';

class CyberGlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final double fillOpacity;
  final double borderOpacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CyberGlassPanel({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.fillOpacity = 0.08,
    this.borderOpacity = 0.18,
    this.borderRadius = 12.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: fillOpacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
