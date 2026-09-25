import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip_history_model.dart';

/// OGC KML 2.2 Exporter for [CompletedTrip], compatible with Google Earth and GIS software.
class KmlExporter {
  /// Converts a [CompletedTrip] into standard KML 2.2 XML string.
  static String toKmlString(CompletedTrip trip) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>Trip ${trip.formattedDate}</name>');
    buffer.writeln('    <description>Live Tracker Route • ${trip.formattedDistance} in ${trip.formattedDuration}</description>');

    // Route Style
    buffer.writeln('    <Style id="routeStyle">');
    buffer.writeln('      <LineStyle>');
    buffer.writeln('        <color>ff00e5ff</color>'); // AABBGGRR format: cyan
    buffer.writeln('        <width>5</width>');
    buffer.writeln('      </LineStyle>');
    buffer.writeln('    </Style>');

    // Start Placemark
    if (trip.routePoints.isNotEmpty) {
      final start = trip.routePoints.first;
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>Start</name>');
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${start.longitude},${start.latitude},${start.altitude ?? 0}</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }

    // Finish Placemark
    if (trip.routePoints.length > 1) {
      final finish = trip.routePoints.last;
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>Finish</name>');
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${finish.longitude},${finish.latitude},${finish.altitude ?? 0}</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }

    // Route LineString
    buffer.writeln('    <Placemark>');
    buffer.writeln('      <name>Track</name>');
    buffer.writeln('      <styleUrl>#routeStyle</styleUrl>');
    buffer.writeln('      <LineString>');
    buffer.writeln('        <extrude>1</extrude>');
    buffer.writeln('        <tessellate>1</tessellate>');
    buffer.writeln('        <altitudeMode>clampToGround</altitudeMode>');
    buffer.writeln('        <coordinates>');

    final coords = trip.routePoints
        .map((p) => '${p.longitude},${p.latitude},${p.altitude?.toStringAsFixed(1) ?? '0'}')
        .join(' ');
    buffer.writeln('          $coords');

    buffer.writeln('        </coordinates>');
    buffer.writeln('      </LineString>');
    buffer.writeln('    </Placemark>');

    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');

    return buffer.toString();
  }

  /// Exports and triggers native OS Share Sheet for .kml file.
  static Future<void> exportAndShare(CompletedTrip trip) async {
    final kmlData = toKmlString(trip);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'trip_${trip.id}.kml';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(kmlData);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/vnd.google-earth.kml+xml')],
        subject: 'Trip KML - ${trip.formattedDate}',
        text: 'Google Earth route from Live Tracker • ${trip.formattedDistance} in ${trip.formattedDuration}',
      ),
    );
  }
}
