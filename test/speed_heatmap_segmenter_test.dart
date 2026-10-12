import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/trip_history_model.dart';
import 'package:live_tracker/utils/speed_heatmap_segmenter.dart';

void main() {
  group('SpeedHeatmapSegmenter Tests', () {
    test('getColorForSpeed categorizes correctly into 4 tiers', () {
      expect(SpeedHeatmapSegmenter.getColorForSpeed(0.0), SpeedHeatmapSegmenter.tierSlowColor);
      expect(SpeedHeatmapSegmenter.getColorForSpeed(19.9), SpeedHeatmapSegmenter.tierSlowColor);

      expect(SpeedHeatmapSegmenter.getColorForSpeed(20.0), SpeedHeatmapSegmenter.tierCruiseColor);
      expect(SpeedHeatmapSegmenter.getColorForSpeed(44.9), SpeedHeatmapSegmenter.tierCruiseColor);

      expect(SpeedHeatmapSegmenter.getColorForSpeed(45.0), SpeedHeatmapSegmenter.tierFastColor);
      expect(SpeedHeatmapSegmenter.getColorForSpeed(74.9), SpeedHeatmapSegmenter.tierFastColor);

      expect(SpeedHeatmapSegmenter.getColorForSpeed(75.0), SpeedHeatmapSegmenter.tierSprintColor);
      expect(SpeedHeatmapSegmenter.getColorForSpeed(120.0), SpeedHeatmapSegmenter.tierSprintColor);
    });

    test('getLabelForSpeed provides correct tier descriptions', () {
      expect(SpeedHeatmapSegmenter.getLabelForSpeed(15.0), contains('Slow'));
      expect(SpeedHeatmapSegmenter.getLabelForSpeed(30.0), contains('Cruise'));
      expect(SpeedHeatmapSegmenter.getLabelForSpeed(60.0), contains('Fast'));
      expect(SpeedHeatmapSegmenter.getLabelForSpeed(90.0), contains('Sprint'));
    });

    test('segmentRoute returns empty list when points are fewer than 2', () {
      expect(SpeedHeatmapSegmenter.segmentRoute([]), isEmpty);
      expect(
        SpeedHeatmapSegmenter.segmentRoute([
          RoutePoint(latitude: -6.2, longitude: 106.8, timestamp: 1000, speed: 25.0),
        ]),
        isEmpty,
      );
    });

    test('segmentRoute produces single segment for uniform speed', () {
      final points = [
        RoutePoint(latitude: -6.200, longitude: 106.800, timestamp: 1000, speed: 30.0),
        RoutePoint(latitude: -6.201, longitude: 106.801, timestamp: 2000, speed: 32.0),
        RoutePoint(latitude: -6.202, longitude: 106.802, timestamp: 3000, speed: 35.0),
      ];

      final segments = SpeedHeatmapSegmenter.segmentRoute(points);
      expect(segments.length, 1);
      expect(segments.first.color, SpeedHeatmapSegmenter.tierCruiseColor);
      expect(segments.first.points.length, 3);
    });

    test('segmentRoute splits segments when crossing speed tiers with point overlap', () {
      final points = [
        // Tier 1: Slow (< 20)
        RoutePoint(latitude: -6.200, longitude: 106.800, timestamp: 1000, speed: 10.0),
        RoutePoint(latitude: -6.201, longitude: 106.801, timestamp: 2000, speed: 15.0),
        // Tier 3: Fast (45 - 75)
        RoutePoint(latitude: -6.202, longitude: 106.802, timestamp: 3000, speed: 60.0),
        RoutePoint(latitude: -6.203, longitude: 106.803, timestamp: 4000, speed: 65.0),
        // Tier 4: Sprint (> 75)
        RoutePoint(latitude: -6.204, longitude: 106.804, timestamp: 5000, speed: 85.0),
        RoutePoint(latitude: -6.205, longitude: 106.805, timestamp: 6000, speed: 90.0),
      ];

      final segments = SpeedHeatmapSegmenter.segmentRoute(points);
      expect(segments.length, 3);
      expect(segments[0].color, SpeedHeatmapSegmenter.tierSlowColor);
      expect(segments[1].color, SpeedHeatmapSegmenter.tierFastColor);
      expect(segments[2].color, SpeedHeatmapSegmenter.tierSprintColor);

      // Verify boundary point overlap to ensure continuous polyline rendering
      expect(segments[0].points.last, segments[1].points.first);
      expect(segments[1].points.last, segments[2].points.first);
    });
  });
}
