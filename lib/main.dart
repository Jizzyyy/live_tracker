import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/core/app_theme.dart';
import 'src/features/settings/providers/settings_provider.dart';
import 'src/features/tracking/presentation/live_tracker_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LiveTrackerApp(),
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
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      // Temporarily bypass splash screen to speed up testing during overhaul
      home: const LiveTrackerScreen(),
    );
  }
}
