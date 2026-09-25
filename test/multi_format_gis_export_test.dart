import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/models/trip_history_model.dart';
import 'package:live_tracker/utils/gpx_exporter.dart';
import 'package:live_tracker/utils/geojson_exporter.dart';
import 'package:live_tracker/utils/kml_exporter.dart';

void main() {
  group('Multi-Format GIS Exporters Test (GPX, GeoJSON, KML)', () {
    final now = DateTime.utc(2026, 9, 25, 12, 0, 0);
    final trip = CompletedTrip(
      id: 'gis_test_101',
      startTime: now.subtract(const Duration(minutes: 45)),
      endTime: now,
      durationSeconds: 2700,
      distanceMeters: 8500.0,
      avgSpeedKmh: 11.3,
      maxSpeedKmh: 24.5,
      routePoints: [
        RoutePoint(latitude: -6.1754, longitude: 106.8272, timestamp: 1000, altitude: 15.0, speed: 10.0),
        RoutePoint(latitude: -6.1800, longitude: 106.8300, timestamp: 2000, altitude: 18.5, speed: 14.0),
        RoutePoint(latitude: -6.1850, longitude: 106.8350, timestamp: 3000, altitude: 22.0, speed: 18.0),
      ],
    );

    test('GPX 1.1 Exporter generates valid XML structure and tags', () {
      final gpx = GpxExporter.toGpxString(trip);
      expect(gpx, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1"'));
      expect(gpx, contains('<trkpt lat="-6.1754" lon="106.8272">'));
      expect(gpx, contains('<ele>15.0</ele>'));
      expect(gpx, contains('</trkpt>'));
      expect(gpx, contains('</gpx>'));
    });

    test('GeoJSON Exporter generates valid RFC 7946 FeatureCollection and LineString', () {
      final jsonStr = GeoJsonExporter.toGeoJsonString(trip);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['type'], 'FeatureCollection');
      final features = decoded['features'] as List;
      expect(features.length, 1);

      final feature = features.first as Map<String, dynamic>;
      expect(feature['type'], 'Feature');
      expect(feature['geometry']['type'], 'LineString');

      final coords = feature['geometry']['coordinates'] as List;
      expect(coords.length, 3);
      // GeoJSON coordinate order: [lon, lat, alt]
      expect(coords[0][0], 106.8272);
      expect(coords[0][1], -6.1754);
      expect(coords[0][2], 15.0);

      expect(feature['properties']['id'], 'gis_test_101');
      expect(feature['properties']['pointCount'], 3);
    });

    test('KML 2.2 Exporter generates valid OGC KML with Start/Finish and LineString', () {
      final kml = KmlExporter.toKmlString(trip);
      expect(kml, contains('<kml xmlns="http://www.opengis.net/kml/2.2">'));
      expect(kml, contains('<name>Start</name>'));
      expect(kml, contains('<coordinates>106.8272,-6.1754,15.0</coordinates>'));
      expect(kml, contains('<name>Finish</name>'));
      expect(kml, contains('<coordinates>106.835,-6.185,22.0</coordinates>'));
      expect(kml, contains('<LineString>'));
      expect(kml, contains('</kml>'));
    });
  });
}
