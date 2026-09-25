import 'package:flutter/services.dart';

/// Lightweight battery level reader via native platform channel.
class BatteryService {
  static const _channel = MethodChannel('com.example.live_tracker/battery');

  /// Returns current battery percentage (0-100), or null if unavailable.
  static Future<int?> getBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      if (level != null && level >= 0) return level;
    } catch (_) {}
    return null;
  }
}
