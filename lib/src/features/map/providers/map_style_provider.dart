import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapStyle {
  const MapStyle({required this.name, required this.urlTemplate, required this.attribution});
  final String name;
  final String urlTemplate;
  final String attribution;
}

const _mapStyles = [
  MapStyle(
    name: 'Standard',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap contributors',
  ),
  MapStyle(
    name: 'Humanitarian',
    urlTemplate: 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap contributors, HOT',
  ),
  MapStyle(
    name: 'Light',
    urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    attribution: 'CartoDB, OpenStreetMap contributors',
  ),
  MapStyle(
    name: 'Dark',
    urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    attribution: 'CartoDB, OpenStreetMap contributors',
  ),
];

List<MapStyle> get availableMapStyles => _mapStyles;

final mapStyleProvider = StateProvider<MapStyle>((ref) => _mapStyles.first);
