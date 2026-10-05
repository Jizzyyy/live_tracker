import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';

void main() {
  group('TacticalPingSerializationTest', () {
    test('TacticalPing correctly serializes and deserializes across all cue types', () {
      final now = DateTime.now();
      for (final cue in TacticalCueType.values) {
        final ping = TacticalPing(
          id: 'ping_123_${cue.name}',
          userId: 'usr_alpha',
          senderName: 'Viper Leader',
          cue: cue,
          latitude: -6.2088,
          longitude: 106.8456,
          timestamp: now,
          note: 'Perhatikan kondisi jalan',
        );

        final json = ping.toJson();
        expect(json['id'], 'ping_123_${cue.name}');
        expect(json['userId'], 'usr_alpha');
        expect(json['senderName'], 'Viper Leader');
        expect(json['cue'], cue.name);
        expect(json['lat'], -6.2088);
        expect(json['lng'], 106.8456);
        expect(json['note'], 'Perhatikan kondisi jalan');

        final reconstructed = TacticalPing.fromJson(json);
        expect(reconstructed.id, ping.id);
        expect(reconstructed.userId, ping.userId);
        expect(reconstructed.senderName, ping.senderName);
        expect(reconstructed.cue, cue);
        expect(reconstructed.latitude, ping.latitude);
        expect(reconstructed.longitude, ping.longitude);
        expect(reconstructed.note, ping.note);
      }
    });

    test('TacticalCueType extension provides proper human-readable labels and short codes', () {
      expect(TacticalCueType.regroup.shortCode, 'REGROUP');
      expect(TacticalCueType.regroup.label, contains('Kumpul'));
      expect(TacticalCueType.hazard.shortCode, 'HAZARD');
      expect(TacticalCueType.hazard.label, contains('Bahaya'));
      expect(TacticalCueType.fuel.shortCode, 'FUEL');
      expect(TacticalCueType.turnLeft.shortCode, 'TURN L');
      expect(TacticalCueType.turnRight.shortCode, 'TURN R');
      expect(TacticalCueType.rest.shortCode, 'REST');
    });

    test('TacticalPing expires correctly after 8 seconds', () {
      final freshPing = TacticalPing(
        id: 'fresh_1',
        userId: 'usr_1',
        cue: TacticalCueType.regroup,
        timestamp: DateTime.now(),
      );
      expect(freshPing.isExpired, isFalse);

      final oldPing = TacticalPing(
        id: 'old_1',
        userId: 'usr_1',
        cue: TacticalCueType.regroup,
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(oldPing.isExpired, isTrue);
    });

    test('callerDisplayName falls back correctly when senderName is absent', () {
      final withName = TacticalPing(
        id: 'p1',
        userId: '42b7',
        senderName: 'Apex Predator',
        cue: TacticalCueType.regroup,
        timestamp: DateTime.now(),
      );
      expect(withName.callerDisplayName, 'Apex Predator');

      final withoutName = TacticalPing(
        id: 'p2',
        userId: '42b7',
        senderName: null,
        cue: TacticalCueType.regroup,
        timestamp: DateTime.now(),
      );
      expect(withoutName.callerDisplayName, 'User 42b7');

      final emptyName = TacticalPing(
        id: 'p3',
        userId: '42b7',
        senderName: '   ',
        cue: TacticalCueType.regroup,
        timestamp: DateTime.now(),
      );
      expect(emptyName.callerDisplayName, 'User 42b7');
    });
  });
}
