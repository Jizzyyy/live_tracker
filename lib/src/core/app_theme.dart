import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF1A73E8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      );
}
