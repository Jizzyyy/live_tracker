import 'package:flutter/services.dart';

/// Sound and Haptic Manager for Emergency SOS and Convoy alerts.
/// Respects user preferences for acoustic sound and tactile haptics.
class SoundManager {
  static DateTime _lastAlarmTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Triggers an acoustic emergency alarm and heavy haptic feedback
  static Future<void> playEmergencyAlarm({bool soundEnabled = true, bool hapticEnabled = true}) async {
    final now = DateTime.now();
    // Throttle repeated triggers to once every 2 seconds
    if (now.difference(_lastAlarmTime).inMilliseconds < 2000) return;
    _lastAlarmTime = now;

    try {
      if (soundEnabled) {
        await SystemSound.play(SystemSoundType.alert);
      }
      if (hapticEnabled) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  /// Triggers a warning beep and tactile vibration for convoy separation
  static Future<void> playWarningBeep({bool soundEnabled = true, bool hapticEnabled = true}) async {
    final now = DateTime.now();
    if (now.difference(_lastAlarmTime).inMilliseconds < 3000) return;
    _lastAlarmTime = now;

    try {
      if (soundEnabled) {
        await SystemSound.play(SystemSoundType.alert);
      }
      if (hapticEnabled) {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }
}
