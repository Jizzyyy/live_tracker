import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/src/core/services/battery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.live_tracker/battery');

  group('BatteryService TTL Cache Tests', () {
    int nativeCallCount = 0;
    int mockBatteryValue = 85;

    setUp(() {
      nativeCallCount = 0;
      mockBatteryValue = 85;
      BatteryService.clearCache();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getBatteryLevel') {
          nativeCallCount++;
          return mockBatteryValue;
        }
        return null;
      });
    });

    tearDown(() {
      BatteryService.clearCache();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Initial call fetches from native platform channel', () async {
      final level = await BatteryService.getBatteryLevel();
      expect(level, 85);
      expect(nativeCallCount, 1);
    });

    test('Subsequent rapid calls return cached level without invoking native channel', () async {
      // 1st call
      final first = await BatteryService.getBatteryLevel();
      expect(first, 85);
      expect(nativeCallCount, 1);

      // Mutate native value to verify cache shields against premature re-query
      mockBatteryValue = 42;

      // 2nd call immediately
      final second = await BatteryService.getBatteryLevel();
      expect(second, 85); // Still cached
      expect(nativeCallCount, 1); // Native method was NOT invoked again

      // 3rd call immediately
      final third = await BatteryService.getBatteryLevel();
      expect(third, 85);
      expect(nativeCallCount, 1);
    });

    test('forceRefresh bypasses cache and queries native channel immediately', () async {
      await BatteryService.getBatteryLevel();
      expect(nativeCallCount, 1);

      mockBatteryValue = 70;
      final refreshed = await BatteryService.getBatteryLevel(forceRefresh: true);
      expect(refreshed, 70);
      expect(nativeCallCount, 2);
    });
  });
}
