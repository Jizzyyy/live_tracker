import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryGreen = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFD600);
  static const Color dangerRed = Color(0xFFFF1744);

  // Dark Palette
  static const Color darkCanvas = Color(0xFF0B0D11);
  static const Color darkSurface = Color(0xFF12151B);
  static const Color darkBorder = Color(0x1FFFFFFF);

  // Light Palette
  static const Color lightCanvas = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0x1F000000);

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCanvas,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: secondaryGreen,
        tertiary: warningAmber,
        error: dangerRed,
        surface: darkSurface,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        labelSmall: GoogleFonts.jetBrainsMono(color: Colors.white60, fontSize: 11, letterSpacing: 1.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightCanvas,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007AFF),
        secondary: secondaryGreen,
        tertiary: warningAmber,
        error: dangerRed,
        surface: lightSurface,
        onSurface: Color(0xFF0D1117),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.inter(color: const Color(0xFF0D1117), fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: GoogleFonts.inter(color: const Color(0xFF0D1117), fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFF0D1117), fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF4A5568), fontSize: 14),
        labelSmall: GoogleFonts.jetBrainsMono(color: const Color(0xFF718096), fontSize: 11, letterSpacing: 1.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0D1117)),
        titleTextStyle: TextStyle(color: Color(0xFF0D1117), fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
