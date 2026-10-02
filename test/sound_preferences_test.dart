import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/utils/sound_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundPreferencesTest', () {
    int soundAlertCount = 0;
    int hapticFeedbackCount = 0;

    setUp(() {
      soundAlertCount = 0;
      hapticFeedbackCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'SystemSound.play') {
          soundAlertCount++;
        } else if (methodCall.method == 'HapticFeedback.vibrate') {
          hapticFeedbackCount++;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('Emergency alarm plays sound and haptics when both enabled', () async {
      await SoundManager.playEmergencyAlarm(soundEnabled: true, hapticEnabled: true);
      expect(soundAlertCount, 1);
      expect(hapticFeedbackCount, greaterThanOrEqualTo(1));
    });

    test('Emergency alarm silences sound when soundEnabled is false', () async {
      await Future.delayed(const Duration(milliseconds: 2100)); // bypass throttle
      await SoundManager.playEmergencyAlarm(soundEnabled: false, hapticEnabled: true);
      expect(soundAlertCount, 0);
      expect(hapticFeedbackCount, greaterThanOrEqualTo(1));
    });

    test('Emergency alarm silences haptic when hapticEnabled is false', () async {
      await Future.delayed(const Duration(milliseconds: 2100)); // bypass throttle
      await SoundManager.playEmergencyAlarm(soundEnabled: true, hapticEnabled: false);
      expect(soundAlertCount, 1);
      expect(hapticFeedbackCount, 0);
    });
  });
}
