import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapStyle {
  const MapStyle({
    required this.name,
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const [],
  });
  final String name;
  final String urlTemplate;
  final String attribution;
  final List<String> subdomains;
}

const _mapStyles = [
  MapStyle(
    name: 'Dark Matter',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution: 'CartoDB, OpenStreetMap contributors',
    subdomains: ['a', 'b', 'c', 'd'],
  ),
  MapStyle(
    name: 'Voyager',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    attribution: 'CartoDB, OpenStreetMap contributors',
    subdomains: ['a', 'b', 'c', 'd'],
  ),
  MapStyle(
    name: 'Standard',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap contributors',
  ),
  MapStyle(
    name: 'Positron',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    attribution: 'CartoDB, OpenStreetMap contributors',
    subdomains: ['a', 'b', 'c', 'd'],
  ),
];

List<MapStyle> get availableMapStyles => _mapStyles;

final mapStyleProvider = StateProvider<MapStyle>((ref) => _mapStyles.first);
