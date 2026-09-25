import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/tracker_models.dart';
import 'package:live_tracker/models/trip_history_model.dart';

void main() {
  group('TripSession & CompletedTrip Telemetry Tests', () {
    test('TripSession formatting formats distance, duration, and speed accurately', () {
      const shortTrip = TripSession(
        distanceMeters: 450.0,
        activeDurationSeconds: 85,
        currentSpeedKmh: 18.5,
        avgSpeedKmh: 16.2,
      );
      expect(shortTrip.formattedDistance, '450 m');
      expect(shortTrip.formattedDuration, '01:25');
      expect(shortTrip.formattedSpeed, '18.5');

      const longTrip = TripSession(
        distanceMeters: 12450.0,
        activeDurationSeconds: 3725,
        currentSpeedKmh: 24.0,
        avgSpeedKmh: 21.3,
      );
      expect(longTrip.formattedDistance, '12.45 km');
      expect(longTrip.formattedDuration, '1:02:05');
    });

    test('CompletedTrip calculates pace and elevation metrics accurately', () {
      final now = DateTime.now();
      final trip = CompletedTrip(
        id: 'test_trip_1',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now,
        durationSeconds: 1800, // 30 minutes
        distanceMeters: 6000.0, // 6 km -> 5 min/km (300 sec/km)
        avgSpeedKmh: 12.0,
        maxSpeedKmh: 18.0,
        routePoints: [
          RoutePoint(latitude: -6.2000, longitude: 106.8000, timestamp: 1000, altitude: 25.0),
          RoutePoint(latitude: -6.2010, longitude: 106.8010, timestamp: 2000, altitude: 30.0), // +5m
          RoutePoint(latitude: -6.2020, longitude: 106.8020, timestamp: 3000, altitude: 28.0), // -2m
          RoutePoint(latitude: -6.2030, longitude: 106.8030, timestamp: 4000, altitude: 45.0), // +17m
          RoutePoint(latitude: -6.2040, longitude: 106.8040, timestamp: 5000, altitude: 40.0), // -5m
        ],
      );

      // Pace = 1800s / 6km = 300s/km = 05'00" /km
      expect(trip.formattedPace, '05\'00" /km');

      // Elevation Gain: +5m + 17m = 22m
      expect(trip.elevationGainMeters, closeTo(22.0, 0.1));
      expect(trip.formattedElevationGain, '+22 m');

      // Elevation Loss: -2m + -5m = 7m
      expect(trip.elevationLossMeters, closeTo(7.0, 0.1));
      expect(trip.formattedElevationLoss, '-7 m');

      // Min/Max Altitude
      expect(trip.minAltitude, 25.0);
      expect(trip.maxAltitude, 45.0);
      expect(trip.formattedMinAltitude, '25 m');
      expect(trip.formattedMaxAltitude, '45 m');
    });
  });
}
