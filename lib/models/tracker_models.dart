import 'package:flutter/foundation.dart';

enum TrackingConnectionStatus { disconnected, reconnecting, connected }
enum TripSessionState { inactive, active, paused }

@immutable
class AppSettings {
  const AppSettings({
    this.serverUrl = 'wss://live-tracker-backend.onrender.com',
    this.highAccuracyGps = true,
    this.backgroundService = true,
    this.isDarkMode = true,
    this.googleMapsApiKey = '',
    this.cartoApiKey = '',
  });

  final String serverUrl;
  final bool highAccuracyGps;
  final bool backgroundService;
  final bool isDarkMode;
  final String googleMapsApiKey;
  final String cartoApiKey;

  AppSettings copyWith({
    String? serverUrl,
    bool? highAccuracyGps,
    bool? backgroundService,
    bool? isDarkMode,
    String? googleMapsApiKey,
    String? cartoApiKey,
  }) {
    return AppSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      highAccuracyGps: highAccuracyGps ?? this.highAccuracyGps,
      backgroundService: backgroundService ?? this.backgroundService,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      googleMapsApiKey: googleMapsApiKey ?? this.googleMapsApiKey,
      cartoApiKey: cartoApiKey ?? this.cartoApiKey,
    );
  }
}

@immutable
class MapStyleOption {
  const MapStyleOption({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.subdomains = const ['a', 'b', 'c'],
    required this.attribution,
  });
  final String id;
  final String name;
  final String urlTemplate;
  final List<String> subdomains;
  final String attribution;
}

@immutable
class MemberLocation {
  const MemberLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
    this.avatarUrl,
    this.speedKmh,
    this.heading,
    this.batteryPercent,
    required this.lastUpdated,
    this.isIdle = false,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String? name;
  final String? avatarUrl;
  final double? speedKmh;
  final double? heading;
  final int? batteryPercent;
  final DateTime lastUpdated;
  final bool isIdle;

  factory MemberLocation.fromJson(Map<String, dynamic> json) {
    return MemberLocation(
      id: json['userId'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      speedKmh: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      batteryPercent: json['battery'] as int?,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      isIdle: json['isIdle'] as bool? ?? false,
    );
  }
}

@immutable
class TripSession {
  const TripSession({
    this.state = TripSessionState.inactive,
    this.distanceMeters = 0.0,
    this.activeDurationSeconds = 0,
    this.currentSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
  });

  final TripSessionState state;
  final double distanceMeters;
  final int activeDurationSeconds;
  final double currentSpeedKmh;
  final double avgSpeedKmh;

  String get formattedDistance {
    if (distanceMeters < 1000) return '${distanceMeters.toStringAsFixed(0)} m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get formattedDuration {
    final h = activeDurationSeconds ~/ 3600;
    final m = ((activeDurationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (activeDurationSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get formattedSpeed => currentSpeedKmh.toStringAsFixed(1);

  TripSession copyWith({
    TripSessionState? state,
    double? distanceMeters,
    int? activeDurationSeconds,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
  }) {
    return TripSession(
      state: state ?? this.state,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      activeDurationSeconds: activeDurationSeconds ?? this.activeDurationSeconds,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
    );
  }
}

@immutable
class SosAlert {
  final String userId;
  final String note;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  const SosAlert({
    required this.userId,
    required this.note,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) => SosAlert(
    userId: json['userId'] as String? ?? 'unknown',
    note: json['note'] as String? ?? 'Bantuan Darurat Diperlukan!',
    latitude: (json['lat'] as num?)?.toDouble(),
    longitude: (json['lng'] as num?)?.toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    ),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'note': note,
    if (latitude != null) 'lat': latitude,
    if (longitude != null) 'lng': longitude,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };
}

enum PoiCategory { rendezvous, fuel, hazard, rest }

@immutable
class SharedPoi {
  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final PoiCategory category;
  final String createdBy;
  final DateTime createdAt;

  const SharedPoi({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lat': latitude,
    'lng': longitude,
    'category': category.name,
    'createdBy': createdBy,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory SharedPoi.fromJson(Map<String, dynamic> json) => SharedPoi(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Tactical POI',
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lng'] as num).toDouble(),
    category: PoiCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => PoiCategory.rendezvous,
    ),
    createdBy: json['createdBy'] as String? ?? 'Member',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    ),
  );
}
