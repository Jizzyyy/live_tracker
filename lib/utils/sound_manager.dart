import 'package:flutter/services.dart';
import '../models/tracker_models.dart';

/// Sound and Haptic Manager for Emergency SOS and Convoy alerts.
/// Respects user preferences for acoustic sound and tactile haptics.
class SoundManager {
  static DateTime _lastAlarmTime = DateTime.fromMillisecondsSinceEpoch(0);
  static DateTime _lastCueTime = DateTime.fromMillisecondsSinceEpoch(0);
  static DateTime _lastHazardTime = DateTime.fromMillisecondsSinceEpoch(0);

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

  /// Triggers sharp acoustic hazard warning and tactile pulse when within 150m geofence
  static Future<void> playHazardProximityAlert({
    bool soundEnabled = true,
    bool hapticEnabled = true,
  }) async {
    final now = DateTime.now();
    if (now.difference(_lastHazardTime).inMilliseconds < 4000) return;
    _lastHazardTime = now;

    try {
      if (soundEnabled) {
        await SystemSound.play(SystemSoundType.alert);
        await Future.delayed(const Duration(milliseconds: 140));
        await SystemSound.play(SystemSoundType.alert);
      }
      if (hapticEnabled) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  /// Triggers distinctive acoustic pulses tailored to specific tactical cues
  static Future<void> playTacticalCue(
    TacticalCueType cue, {
    bool soundEnabled = true,
    bool hapticEnabled = true,
  }) async {
    final now = DateTime.now();
    if (now.difference(_lastCueTime).inMilliseconds < 1000) return;
    _lastCueTime = now;

    try {
      switch (cue) {
        case TacticalCueType.hazard:
          if (soundEnabled) {
            await SystemSound.play(SystemSoundType.alert);
            await Future.delayed(const Duration(milliseconds: 120));
            await SystemSound.play(SystemSoundType.alert);
          }
          if (hapticEnabled) {
            await HapticFeedback.heavyImpact();
            await Future.delayed(const Duration(milliseconds: 100));
            await HapticFeedback.heavyImpact();
          }
          break;

        case TacticalCueType.regroup:
          if (soundEnabled) {
            await SystemSound.play(SystemSoundType.alert);
            await Future.delayed(const Duration(milliseconds: 200));
            await SystemSound.play(SystemSoundType.click);
          }
          if (hapticEnabled) {
            await HapticFeedback.mediumImpact();
          }
          break;

        case TacticalCueType.turnLeft:
        case TacticalCueType.turnRight:
          if (soundEnabled) {
            await SystemSound.play(SystemSoundType.click);
            await Future.delayed(const Duration(milliseconds: 150));
            await SystemSound.play(SystemSoundType.click);
          }
          if (hapticEnabled) {
            await HapticFeedback.selectionClick();
            await Future.delayed(const Duration(milliseconds: 150));
            await HapticFeedback.selectionClick();
          }
          break;

        case TacticalCueType.fuel:
        case TacticalCueType.rest:
          if (soundEnabled) {
            await SystemSound.play(SystemSoundType.click);
          }
          if (hapticEnabled) {
            await HapticFeedback.lightImpact();
          }
          break;
      }
    } catch (_) {}
  }
}

