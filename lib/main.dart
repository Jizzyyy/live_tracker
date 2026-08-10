import 'package:flutter/material.dart';
import 'src/features/map/presentation/map_screen.dart';

void main() {
  runApp(const LiveTrackerApp());
}

class LiveTrackerApp extends StatelessWidget {
  const LiveTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapScreen(),
    );
  }
}
