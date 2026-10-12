import 'package:latlong2/latlong.dart';

class MapDefaults {
  static const initialCenter = LatLng(-6.200000, 106.816666);
  static const initialZoom = 13.0;
  static const focusedZoom = 16.0;
}

class MapTileUrls {
  static const esriDarkCanvas =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
  static const esriLightCanvas =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}';
  static const esriSatellite =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const osmStandard =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String cartoDark([String keyParam = '']) =>
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png$keyParam';
  static String cartoLight([String keyParam = '']) =>
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png$keyParam';

  static String googleRoadmap(String apiKey) =>
      'https://mt0.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=$apiKey';
  static String googleSatellite(String apiKey) =>
      'https://mt0.google.com/vt/lyrs=y&x={x}&y={y}&z={z}&key=$apiKey';
  static String googleTerrain(String apiKey) =>
      'https://mt0.google.com/vt/lyrs=p&x={x}&y={y}&z={z}&key=$apiKey';
}

