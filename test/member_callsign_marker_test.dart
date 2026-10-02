import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/widgets/custom_user_marker.dart';

void main() {
  group('MemberCallsignMarkerTest', () {
    testWidgets('Renders custom callsign badge when name is present', (tester) async {
      final location = MemberLocation(
        id: 'usr_falcon',
        latitude: -6.2,
        longitude: 106.8,
        name: 'Falcon Leader',
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomUserMarker(
                location: location,
                color: Colors.blue,
                isLocalUser: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Falcon Leader'), findsOneWidget);
    });

    testWidgets('Renders YOU when local user has no custom name', (tester) async {
      final location = MemberLocation(
        id: 'usr_me',
        latitude: -6.2,
        longitude: 106.8,
        name: null,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomUserMarker(
                location: location,
                color: Colors.cyan,
                isLocalUser: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('YOU'), findsOneWidget);
    });

    testWidgets('Renders User <id> fallback when remote member has no name', (tester) async {
      final location = MemberLocation(
        id: '42b7',
        latitude: -6.2,
        longitude: 106.8,
        name: '',
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomUserMarker(
                location: location,
                color: Colors.amber,
                isLocalUser: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('User 42b7'), findsOneWidget);
    });
  });
}
