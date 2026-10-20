import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryGreen = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFD600);
  static const Color dangerRed = Color(0xFFFF1744);
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color accentBlue = Color(0xFF0284C7);

  // Dark Palette
  static const Color darkCanvas = Color(0xFF0B0D11);
  static const Color darkSurface = Color(0xFF12151B);
  static const Color darkCard = Color(0xFF1E232D);
  static const Color darkBorder = Color(0x1FFFFFFF);

  // Light Palette
  static const Color lightCanvas = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0x1F000000);
  static const Color textDark = Color(0xFF0D1117);

  // Design Tokens: Border Radii
  static const double rSm = 8.0;
  static const double rMd = 12.0;
  static const double rLg = 16.0;
  static const double rXl = 20.0;
  static const double r2Xl = 24.0;
  static const double rSheet = 28.0;
  static const double rHub = 32.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(rSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(rMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(rLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(rXl);
  static final BorderRadius borderRadius2Xl = BorderRadius.circular(r2Xl);
  static const BorderRadius borderRadiusSheet = BorderRadius.vertical(top: Radius.circular(rSheet));
  static final BorderRadius borderRadiusHub = BorderRadius.circular(rHub);

  // Design Tokens: EdgeInsets Spacing
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets paddingModal = EdgeInsets.fromLTRB(20, 16, 20, 24);
  static const EdgeInsets paddingCard = EdgeInsets.all(16.0);
  static const EdgeInsets paddingCardLg = EdgeInsets.all(20.0);
  static const EdgeInsets paddingPill = EdgeInsets.symmetric(horizontal: 10, vertical: 4);

  // Design Tokens: SizedBox Spacers
  static const SizedBox gap4 = SizedBox(width: 4, height: 4);
  static const SizedBox gap8 = SizedBox(width: 8, height: 8);
  static const SizedBox gap12 = SizedBox(width: 12, height: 12);
  static const SizedBox gap16 = SizedBox(width: 16, height: 16);
  static const SizedBox gap20 = SizedBox(width: 20, height: 20);
  static const SizedBox gap24 = SizedBox(width: 24, height: 24);
  static const SizedBox gap32 = SizedBox(width: 32, height: 32);

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
        labelSmall: GoogleFonts.inter(
          color: Colors.white60,
          fontSize: 11,
          letterSpacing: 1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
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
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: GoogleFonts.inter(color: textDark, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF4A5568), fontSize: 14),
        labelSmall: GoogleFonts.inter(
          color: const Color(0xFF718096),
          fontSize: 11,
          letterSpacing: 1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AppTextStyles {
  // HUD & Telemetry Labels (Inter with tabular figures & tracking)
  static TextStyle hudLabel({
    double fontSize = 11,
    Color? color,
    double letterSpacing = 1.2,
    FontWeight fontWeight = FontWeight.bold,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        fontWeight: fontWeight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Digital Tabular Metrics (Inter with tabular figures)
  static TextStyle monoMetric({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Clean UI Titles & Body (Inter)
  static TextStyle title({
    double fontSize = 18,
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );

  static TextStyle body({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );

  static TextStyle caption({
    double fontSize = 11,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );
}
