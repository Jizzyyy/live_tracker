import 'package:flutter/material.dart';
import 'dart:ui';

class PremiumGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool enableBlur;

  const PremiumGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.onTap,
    this.enableBlur = false, // Disabled by default for GPU thermal protection on active map viewport
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final decoration = BoxDecoration(
      color: isDark 
          ? const Color(0xFF12151B).withValues(alpha: enableBlur ? 0.88 : 0.94)
          : const Color(0xFFFFFFFF).withValues(alpha: enableBlur ? 0.88 : 0.95),
      borderRadius: borderRadius,
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.10) 
            : Colors.black.withValues(alpha: 0.08),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withValues(alpha: 0.35) 
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

    final innerContent = Container(
      padding: padding,
      decoration: enableBlur ? decoration : null,
      child: child,
    );

    final glassContent = ClipRRect(
      borderRadius: borderRadius,
      child: enableBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: innerContent,
            )
          : Container(
              padding: padding,
              decoration: decoration,
              child: child,
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
