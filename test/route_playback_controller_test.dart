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
      // testTrip moves South (latitude -6.2000 to -6.2040)
      final heading = controller.currentHeading;
      expect(heading, isNotNull);
      expect(heading!, closeTo(180.0, 1.0));
      controller.dispose();
    });

    test('Heading angle computes East, West and handles stationary clusters', () {
      final now = DateTime.now();
      // Eastbound trip (longitude increases)
      final eastTrip = CompletedTrip(
        id: 'east_trip',
        startTime: now,
        endTime: now.add(const Duration(seconds: 4)),
        durationSeconds: 4,
        distanceMeters: 400.0,
        avgSpeedKmh: 40.0,
        maxSpeedKmh: 50.0,
        routePoints: [
          RoutePoint(latitude: -6.2000, longitude: 106.8000, timestamp: 1000, speed: 30.0),
          RoutePoint(latitude: -6.2000, longitude: 106.8010, timestamp: 2000, speed: 30.0),
          RoutePoint(latitude: -6.2000, longitude: 106.8020, timestamp: 3000, speed: 30.0),
        ],
      );
      final cEast = RoutePlaybackController(trip: eastTrip);
      expect(cEast.currentHeading, closeTo(90.0, 1.0));
      cEast.dispose();

      // Westbound trip (longitude decreases)
      final westTrip = CompletedTrip(
        id: 'west_trip',
        startTime: now,
        endTime: now.add(const Duration(seconds: 4)),
        durationSeconds: 4,
        distanceMeters: 400.0,
        avgSpeedKmh: 40.0,
        maxSpeedKmh: 50.0,
        routePoints: [
          RoutePoint(latitude: -6.2000, longitude: 106.8020, timestamp: 1000, speed: 30.0),
          RoutePoint(latitude: -6.2000, longitude: 106.8010, timestamp: 2000, speed: 30.0),
          RoutePoint(latitude: -6.2000, longitude: 106.8000, timestamp: 3000, speed: 30.0),
        ],
      );
      final cWest = RoutePlaybackController(trip: westTrip);
      expect(cWest.currentHeading, closeTo(270.0, 1.0));
      cWest.dispose();

      // Trip with stationary red-light stop in the middle
      final stopTrip = CompletedTrip(
        id: 'stop_trip',
        startTime: now,
        endTime: now.add(const Duration(seconds: 5)),
        durationSeconds: 5,
        distanceMeters: 300.0,
        avgSpeedKmh: 20.0,
        maxSpeedKmh: 35.0,
        routePoints: [
          RoutePoint(latitude: -6.2000, longitude: 106.8000, timestamp: 1000, speed: 30.0),
          // Stopped at intersection (same coordinates)
          RoutePoint(latitude: -6.2010, longitude: 106.8000, timestamp: 2000, speed: 0.0),
          RoutePoint(latitude: -6.2010, longitude: 106.8000, timestamp: 3000, speed: 0.0),
          // Moving again South
          RoutePoint(latitude: -6.2020, longitude: 106.8000, timestamp: 4000, speed: 30.0),
        ],
      );
      final cStop = RoutePlaybackController(trip: stopTrip);
      cStop.seekToIndex(1); // At stopped point
      // Look-ahead should still find next point moving South (180°) instead of snapping to 0.0!
      expect(cStop.currentHeading, closeTo(180.0, 1.0));
      cStop.dispose();
    });
  });
}
