import 'package:flutter/material.dart';
import 'dart:ui';

class PremiumGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PremiumGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Performance optimization: Lowered sigmaX/Y from 16 to 7.0 for 60/120 FPS GPU fill-rate
    final glassContent = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF12151B).withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.white.withValues(alpha: 0.4),
              width: 0.7,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: glassContent,
        ),
      );
    }
    return glassContent;
  }
}
