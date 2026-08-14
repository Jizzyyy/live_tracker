import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0D10),
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF00E5FF),
        secondary: const Color(0xFF00E676),
        tertiary: const Color(0xFFFFD600),
        error: const Color(0xFFFF1744),
        surface: const Color(0xFF12151B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardTheme(
        color: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00E5FF),
        foregroundColor: Color(0xFF0B0D10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF12151B).withValues(alpha: 0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.displayLarge,
        ),
        displayMedium: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.displayMedium,
        ),
        displaySmall: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.displaySmall,
        ),
        headlineLarge: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.headlineLarge,
        ),
        headlineMedium: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.headlineMedium,
        ),
        headlineSmall: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.headlineSmall,
        ),
        titleLarge: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.titleLarge,
        ),
        titleMedium: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.titleMedium,
        ),
        titleSmall: GoogleFonts.jetbrainsMono(
          textStyle: base.textTheme.titleSmall,
        ),
      ),
    );
  }
}
