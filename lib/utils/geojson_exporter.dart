import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip_history_model.dart';

/// RFC 7946 compliant GeoJSON Exporter for [CompletedTrip].
class GeoJsonExporter {
  /// Converts a [CompletedTrip] into a standard GeoJSON FeatureCollection string.
  static String toGeoJsonString(CompletedTrip trip) {
    final coordinates = <List<dynamic>>[];

    for (final pt in trip.routePoints) {
      if (pt.altitude != null) {
        coordinates.add([pt.longitude, pt.latitude, pt.altitude]);
      } else {
        coordinates.add([pt.longitude, pt.latitude]);
      }
    }

    final geoJsonMap = {
      'type': 'FeatureCollection',
      'generator': 'LiveTracker - Forged by KadhafiINL',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'id': trip.id,
            'name': 'Trip ${trip.formattedDate}',
            'startTime': trip.startTime.toUtc().toIso8601String(),
            'endTime': trip.endTime.toUtc().toIso8601String(),
            'durationSeconds': trip.durationSeconds,
            'distanceMeters': trip.distanceMeters,
            'avgSpeedKmh': trip.avgSpeedKmh,
            'maxSpeedKmh': trip.maxSpeedKmh,
            'formattedDuration': trip.formattedDuration,
            'formattedDistance': trip.formattedDistance,
            'formattedPace': trip.formattedPace,
            'pointCount': trip.routePoints.length,
          },
          'geometry': {
            'type': 'LineString',
            'coordinates': coordinates,
          },
        },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(geoJsonMap);
  }

  /// Exports and triggers native OS Share Sheet for .geojson file.
  static Future<void> exportAndShare(CompletedTrip trip) async {
    final jsonStr = toGeoJsonString(trip);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'trip_${trip.id}.geojson';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(jsonStr);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/geo+json')],
        subject: 'Trip GeoJSON - ${trip.formattedDate}',
        text: 'GeoJSON route from Live Tracker • ${trip.formattedDistance} in ${trip.formattedDuration}',
      ),
    );
  }
}
