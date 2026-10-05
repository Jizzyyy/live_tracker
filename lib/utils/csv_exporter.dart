import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip_history_model.dart';

class CsvExporter {
  /// Converts a [CompletedTrip] into standard comma-separated tabular CSV string
  static String toCsvString(CompletedTrip trip) {
    final buffer = StringBuffer();
    // File metadata comments
    buffer.writeln('# Trip Title: ${trip.displayTitle}');
    buffer.writeln('# Date: ${trip.formattedDate}');
    buffer.writeln('# Total Distance: ${trip.formattedDistance}');
    buffer.writeln('# Total Duration: ${trip.formattedDuration}');
    buffer.writeln('# Moving Duration: ${trip.formattedMovingDuration}');
    buffer.writeln('# Avg Speed: ${trip.formattedAvgSpeed}');
    buffer.writeln('# Max Speed: ${trip.formattedMaxSpeed}');
    buffer.writeln('# Elevation Gain: ${trip.formattedElevationGain}');
    buffer.writeln('# Max Incline Gradient: ${trip.formattedMaxGradient}');
    
    // Tabular CSV Headers
    buffer.writeln('index,timestamp_utc,latitude,longitude,altitude_m,speed_kmh');

    for (int i = 0; i < trip.routePoints.length; i++) {
      final pt = trip.routePoints[i];
      final timeUtc = DateTime.fromMillisecondsSinceEpoch(pt.timestamp, isUtc: true).toIso8601String();
      final alt = pt.altitude != null ? pt.altitude!.toStringAsFixed(1) : '';
      final spd = pt.speed != null ? pt.speed!.toStringAsFixed(1) : '';
      buffer.writeln('$i,$timeUtc,${pt.latitude},${pt.longitude},$alt,$spd');
    }

    return buffer.toString();
  }

  /// Exports and triggers native OS Share Sheet for .csv file
  static Future<void> exportAndShare(CompletedTrip trip) async {
    final csvData = toCsvString(trip);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'trip_${trip.id}.csv';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(csvData);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Trip Telemetry CSV - ${trip.formattedDate}',
        text: 'Data telemetri rute CSV (${trip.displayTitle})',
      ),
    );
  }
}
