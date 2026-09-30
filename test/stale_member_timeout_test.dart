import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';

void main() {
  group('StaleMemberTimeoutTest', () {
    test('Member location is NOT stale when updated recently (<45s)', () {
      final freshMember = MemberLocation(
        id: 'rider_01',
        latitude: -6.2000,
        longitude: 106.8000,
        lastUpdated: DateTime.now().subtract(const Duration(seconds: 15)),
      );

      expect(freshMember.isStale, isFalse);
    });

    test('Member location becomes stale after 45 seconds of no updates', () {
      final staleMember = MemberLocation(
        id: 'rider_lost',
        latitude: -6.2000,
        longitude: 106.8000,
        lastUpdated: DateTime.now().subtract(const Duration(seconds: 50)),
      );

      expect(staleMember.isStale, isTrue);
    });
  });
}
