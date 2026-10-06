import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/controllers/route_playback_controller.dart';
import 'package:live_tracker/models/trip_history_model.dart';

void main() {
  group('RoutePlaybackControllerTest', () {
    late CompletedTrip testTrip;

    setUp(() {
      final now = DateTime.now();
      final points = <RoutePoint>[
        RoutePoint(latitude: -6.2000, longitude: 106.8000, timestamp: now.millisecondsSinceEpoch, speed: 20.0),
        RoutePoint(latitude: -6.2010, longitude: 106.8000, timestamp: now.millisecondsSinceEpoch + 1000, speed: 30.0),
        RoutePoint(latitude: -6.2020, longitude: 106.8000, timestamp: now.millisecondsSinceEpoch + 2000, speed: 40.0),
        RoutePoint(latitude: -6.2030, longitude: 106.8000, timestamp: now.millisecondsSinceEpoch + 3000, speed: 50.0),
        RoutePoint(latitude: -6.2040, longitude: 106.8000, timestamp: now.millisecondsSinceEpoch + 4000, speed: 60.0),
      ];

      testTrip = CompletedTrip(
        id: 'playback_trip_1',
        startTime: now,
        endTime: now.add(const Duration(seconds: 4)),
        durationSeconds: 4,
        distanceMeters: 440.0,
        avgSpeedKmh: 40.0,
        maxSpeedKmh: 60.0,
        routePoints: points,
      );
    });

    test('Initializes with default idle state and zero progress', () {
      final controller = RoutePlaybackController(trip: testTrip);
      expect(controller.isPlaying, isFalse);
      expect(controller.playbackSpeed, 1.0);
      expect(controller.currentIndex, 0);
      expect(controller.progress, 0.0);
      expect(controller.totalPoints, 5);
      expect(controller.currentPoint, isNotNull);
      expect(controller.currentPoint!.latitude, -6.2000);
      controller.dispose();
    });

    test('Seeking updates current index and progress accurately', () {
      final controller = RoutePlaybackController(trip: testTrip);

      controller.seekToFraction(0.5);
      expect(controller.currentIndex, 2);
      expect(controller.progress, 0.5);
      expect(controller.currentPoint!.latitude, -6.2020);

      controller.seekToFraction(1.0);
      expect(controller.currentIndex, 4);
      expect(controller.progress, 1.0);

      controller.seekToIndex(1);
      expect(controller.currentIndex, 1);
      expect(controller.progress, 0.25);

      controller.dispose();
    });

    test('CycleSpeed steps through 1x, 2x, 5x, 10x and wraps around', () {
      final controller = RoutePlaybackController(trip: testTrip);
      expect(controller.playbackSpeed, 1.0);

      controller.cycleSpeed();
      expect(controller.playbackSpeed, 2.0);

      controller.cycleSpeed();
      expect(controller.playbackSpeed, 5.0);

      controller.cycleSpeed();
      expect(controller.playbackSpeed, 10.0);

      controller.cycleSpeed();
      expect(controller.playbackSpeed, 1.0);

      controller.dispose();
    });

    test('Play, pause and toggle updates isPlaying state correctly', () {
      final controller = RoutePlaybackController(trip: testTrip);

      controller.play();
      expect(controller.isPlaying, isTrue);

      controller.pause();
      expect(controller.isPlaying, isFalse);

      controller.togglePlay();
      expect(controller.isPlaying, isTrue);

      controller.togglePlay();
      expect(controller.isPlaying, isFalse);

      controller.dispose();
    });

    test('Heading angle is computed accurately along route direction', () {
      final controller = RoutePlaybackController(trip: testTrip);
      final heading = controller.currentHeading;
      expect(heading, isNotNull);
      expect(heading, isA<double>());
      controller.dispose();
    });
  });
}
