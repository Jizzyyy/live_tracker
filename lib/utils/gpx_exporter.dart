import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip_history_model.dart';

class GpxExporter {
  /// Converts a [CompletedTrip] into standard GPX 1.1 XML string
  static String toGpxString(CompletedTrip trip) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="LiveTracker - Forged by KadhafiINL" '
        'xmlns="http://www.topografix.com/GPX/1/1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');

    // Metadata
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>Trip ${trip.formattedDate}</name>');
    buffer.writeln('    <time>${trip.startTime.toUtc().toIso8601String()}</time>');
    buffer.writeln('  </metadata>');

    // Track
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>Live Tracker Route</name>');
    buffer.writeln('    <type>Cycling/Running</type>');
    buffer.writeln('    <trkseg>');

    for (final pt in trip.routePoints) {
      final timeUtc = DateTime.fromMillisecondsSinceEpoch(pt.timestamp, isUtc: true).toIso8601String();
      buffer.write('      <trkpt lat="${pt.latitude}" lon="${pt.longitude}">');
      if (pt.altitude != null) {
        buffer.write('<ele>${pt.altitude!.toStringAsFixed(1)}</ele>');
      }
      buffer.write('<time>$timeUtc</time>');
      if (pt.speed != null) {
        buffer.write('<extensions><speed>${(pt.speed! / 3.6).toStringAsFixed(2)}</speed></extensions>');
      }
      buffer.writeln('</trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  /// Exports and triggers native OS Share Sheet for .gpx file
  static Future<void> exportAndShare(CompletedTrip trip) async {
    final gpxData = toGpxString(trip);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'trip_${trip.id}.gpx';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(gpxData);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/gpx+xml')],
        subject: 'Trip Export - ${trip.formattedDate}',
        text: 'Exported from Live Tracker • ${trip.formattedDistance} in ${trip.formattedDuration}',
      ),
    );
  }
}
