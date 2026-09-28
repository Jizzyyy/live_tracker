import 'package:flutter/services.dart';

/// Lightweight battery level reader via native platform channel with TTL cache.
class BatteryService {
  static const _channel = MethodChannel('com.example.live_tracker/battery');

  static int? _cachedLevel;
  static int _lastFetchMs = 0;
  static const int ttlMs = 30000; // 30 seconds

  /// Returns current battery percentage (0-100), or null if unavailable.
  /// Throttled by 30-second TTL cache to eliminate redundant Android Binder IPC.
  static Future<int?> getBatteryLevel({bool forceRefresh = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!forceRefresh && _cachedLevel != null && (now - _lastFetchMs < ttlMs)) {
      return _cachedLevel;
    }

    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      if (level != null && level >= 0) {
        _cachedLevel = level;
        _lastFetchMs = now;
        return level;
      }
    } catch (_) {}
    return _cachedLevel;
  }

  /// Clears cache (useful for testing or manual refresh)
  static void clearCache() {
    _cachedLevel = null;
    _lastFetchMs = 0;
  }
}
