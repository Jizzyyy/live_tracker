import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/providers/tracker_providers.dart';

void main() {
  group('Room State & WebSocket Data Models Test', () {
    test('SosAlert serializes and deserializes correctly', () {
      final now = DateTime.now();
      final alert = SosAlert(
        userId: 'node_99',
        note: '⚠️ Kecelakaan / Jatuh',
        latitude: -6.1753,
        longitude: 106.8271,
        timestamp: now,
      );

      final json = alert.toJson();
      expect(json['userId'], 'node_99');
      expect(json['note'], '⚠️ Kecelakaan / Jatuh');
      expect(json['lat'], -6.1753);
      expect(json['lng'], 106.8271);

      final restored = SosAlert.fromJson(json);
      expect(restored.userId, alert.userId);
      expect(restored.note, alert.note);
      expect(restored.latitude, alert.latitude);
      expect(restored.longitude, alert.longitude);
    });

    test('SharedPoi serializes all categories and deserializes correctly', () {
      final now = DateTime.now();
      for (final cat in PoiCategory.values) {
        final poi = SharedPoi(
          id: 'poi_${cat.name}',
          title: 'POI ${cat.name}',
          latitude: -6.2000,
          longitude: 106.8100,
          category: cat,
          createdBy: 'Rider1',
          createdAt: now,
        );

        final json = poi.toJson();
        expect(json['category'], cat.name);

        final restored = SharedPoi.fromJson(json);
        expect(restored.category, cat);
        expect(restored.title, 'POI ${cat.name}');
      }
    });

    test('MemberLocation parses live battery and speed telemetry', () {
      final payload = {
        'userId': 'rider_speedy',
        'lat': -6.2050,
        'lng': 106.8150,
        'speed': 45.5,
        'heading': 180.0,
        'battery': 88,
        'timestamp': 1789000000000,
      };

      final member = MemberLocation.fromJson(payload);
      expect(member.id, 'rider_speedy');
      expect(member.speedKmh, 45.5);
      expect(member.heading, 180.0);
      expect(member.batteryPercent, 88);
      expect(member.latitude, -6.2050);
      expect(member.longitude, 106.8150);
    });

    test('RoomState correctly copies and mutates activeSos and pois', () {
      const initial = RoomState();
      expect(initial.activeSos, isNull);
      expect(initial.pois, isEmpty);

      final alert = SosAlert(
        userId: 'victim_1',
        note: 'Ban bocor',
        timestamp: DateTime.now(),
      );

      final withSos = initial.copyWith(activeSos: () => alert);
      expect(withSos.activeSos, isNotNull);
      expect(withSos.activeSos?.userId, 'victim_1');

      final dismissed = withSos.copyWith(activeSos: () => null);
      expect(dismissed.activeSos, isNull);

      final poi = SharedPoi(
        id: 'p1',
        title: 'Rest Area',
        latitude: -6.2,
        longitude: 106.8,
        category: PoiCategory.rest,
        createdBy: 'Me',
        createdAt: DateTime.now(),
      );

      final withPoi = dismissed.copyWith(pois: {'p1': poi});
      expect(withPoi.pois.length, 1);
      expect(withPoi.pois['p1']?.title, 'Rest Area');
    });
  });
}
