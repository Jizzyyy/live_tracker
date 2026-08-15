import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackbarType { success, warning, error, info }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
  }) {
    // Trigger subtle haptic feedback
    HapticFeedback.lightImpact();

    final Color accentColor = switch (type) {
      SnackbarType.success => const Color(0xFF00E676),
      SnackbarType.warning => const Color(0xFFFFD600),
      SnackbarType.error => const Color(0xFFFF1744),
      SnackbarType.info => const Color(0xFF00E5FF),
    };

    final IconData icon = switch (type) {
      SnackbarType.success => Icons.check_circle_outline,
      SnackbarType.warning => Icons.warning_amber_rounded,
      SnackbarType.error => Icons.error_outline_rounded,
      SnackbarType.info => Icons.info_outline_rounded,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF12151B).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
