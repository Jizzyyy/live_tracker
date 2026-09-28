import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/providers/tracker_providers.dart';

void main() {
  group('RoomSnapshotSynchronization & State Hydration Tests', () {
    test('Hydrates existing room snapshot containing POIs, members, and active SOS', () {
      final serverJoinedPayload = {
        'type': 'room_joined',
        'roomCode': 'ALPHA9',
        'members': ['user_1', 'user_2'],
        'snapshot': {
          'members': [
            {
              'userId': 'user_2',
              'lat': -6.1800,
              'lng': 106.8200,
              'speed': 25.0,
              'heading': 90.0,
              'battery': 75,
              'name': 'Captain',
              'timestamp': 1789000010000,
            },
          ],
          'pois': [
            {
              'id': 'poi_spbu_1',
              'title': 'SPBU KM 19',
              'lat': -6.1850,
              'lng': 106.8300,
              'category': 'fuel',
              'createdBy': 'user_2',
              'createdAt': 1789000005000,
            },
            {
              'id': 'poi_rendezvous_1',
              'title': 'Kumpul Rest Area',
              'lat': -6.1900,
              'lng': 106.8400,
              'category': 'rendezvous',
              'createdBy': 'user_2',
              'createdAt': 1789000008000,
            },
          ],
          'activeSos': {
            'userId': 'user_2',
            'note': '🚨 Motor mogok',
            'lat': -6.1800,
            'lng': 106.8200,
            'timestamp': 1789000009000,
          },
        },
      };

      const initial = RoomState();
      final snapshot = serverJoinedPayload['snapshot'] as Map<String, dynamic>;

      final members = <String, MemberLocation>{};
      for (final m in snapshot['members'] as List) {
        final loc = MemberLocation.fromJson(m as Map<String, dynamic>);
        members[loc.id] = loc;
      }

      final pois = <String, SharedPoi>{};
      for (final p in snapshot['pois'] as List) {
        final poi = SharedPoi.fromJson(p as Map<String, dynamic>);
        pois[poi.id] = poi;
      }

      final activeSos = SosAlert.fromJson(snapshot['activeSos'] as Map<String, dynamic>);

      final hydratedState = initial.copyWith(
        status: TrackingConnectionStatus.connected,
        roomCode: serverJoinedPayload['roomCode'] as String,
        members: members,
        pois: pois,
        activeSos: () => activeSos,
      );

      expect(hydratedState.status, TrackingConnectionStatus.connected);
      expect(hydratedState.roomCode, 'ALPHA9');
      expect(hydratedState.members.length, 1);
      expect(hydratedState.members['user_2']?.name, 'Captain');
      expect(hydratedState.members['user_2']?.batteryPercent, 75);

      expect(hydratedState.pois.length, 2);
      expect(hydratedState.pois['poi_spbu_1']?.category, PoiCategory.fuel);
      expect(hydratedState.pois['poi_rendezvous_1']?.category, PoiCategory.rendezvous);

      expect(hydratedState.activeSos, isNotNull);
      expect(hydratedState.activeSos?.userId, 'user_2');
      expect(hydratedState.activeSos?.note, '🚨 Motor mogok');
    });

    test('RoomState correctly records and clears server error states', () {
      const initial = RoomState();
      expect(initial.lastError, isNull);

      final withError = initial.copyWith(lastError: () => 'Room tidak ditemukan');
      expect(withError.lastError, 'Room tidak ditemukan');

      final cleared = withError.copyWith(lastError: () => null);
      expect(cleared.lastError, isNull);
    });

    test('RoomState correctly updates on connection status transitions', () {
      const initial = RoomState(status: TrackingConnectionStatus.connected);
      expect(initial.status, TrackingConnectionStatus.connected);

      final reconnecting = initial.copyWith(status: TrackingConnectionStatus.reconnecting);
      expect(reconnecting.status, TrackingConnectionStatus.reconnecting);

      final disconnected = reconnecting.copyWith(status: TrackingConnectionStatus.disconnected);
      expect(disconnected.status, TrackingConnectionStatus.disconnected);
    });
  });
}
