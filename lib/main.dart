import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/app_theme.dart';
import 'src/features/map/presentation/map_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LiveTrackerApp(),
    ),
  );
}

class LiveTrackerApp extends StatelessWidget {
  const LiveTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const MapScreen(),
    );
  }
}
