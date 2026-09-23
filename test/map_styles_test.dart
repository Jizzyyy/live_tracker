import 'package:flutter_test/flutter_test.dart';
import 'package:live_tracker/providers/tracker_providers.dart';

void main() {
  group('MapStyleOption & Provider Tests', () {
    test('Default map styles have zero watermark Esri and OSM providers', () {
      final styles = getAvailableMapStyles();
      expect(styles.isNotEmpty, isTrue);
      
      final darkStyle = styles.firstWhere((s) => s.id == 'dark');
      expect(darkStyle.name, contains('Esri'));
      expect(darkStyle.urlTemplate, contains('server.arcgisonline.com'));
      // Must NOT use unauthenticated cartocdn.com which renders watermarks
      expect(darkStyle.urlTemplate, isNot(contains('cartocdn.com')));

      final osmStyle = styles.firstWhere((s) => s.id == 'osm');
      expect(osmStyle.urlTemplate, contains('tile.openstreetmap.org'));

      final satelliteStyle = styles.firstWhere((s) => s.id == 'satellite');
      expect(satelliteStyle.name, contains('Satellite'));
      expect(satelliteStyle.urlTemplate, contains('World_Imagery'));
    });

    test('Injecting CartoDB API key adds authenticated Carto styles', () {
      const testKey = 'test_carto_key_12345';
      final styles = getAvailableMapStyles('', testKey);
      
      final cartoDark = styles.firstWhere((s) => s.id == 'carto_dark');
      expect(cartoDark.urlTemplate, contains('basemaps.cartocdn.com'));
      expect(cartoDark.urlTemplate, contains('?key=$testKey'));
      
      final cartoLight = styles.firstWhere((s) => s.id == 'carto_light');
      expect(cartoLight.urlTemplate, contains('?key=$testKey'));
    });

    test('Injecting Google Maps API key adds roadmap and satellite options', () {
      const googleKey = 'AIzaSyTestGoogleKey';
      final styles = getAvailableMapStyles(googleKey, '');

      final gRoadmap = styles.firstWhere((s) => s.id == 'google_roadmap');
      expect(gRoadmap.urlTemplate, contains('mt0.google.com'));
      expect(gRoadmap.urlTemplate, contains('key=$googleKey'));
    });
  });
}
