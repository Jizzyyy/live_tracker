import 'package:flutter/foundation.dart';

enum TrackingConnectionStatus { disconnected, reconnecting, connected }
enum TripSessionState { inactive, active, paused }

@immutable
class AppSettings {
  const AppSettings({
    this.serverUrl = 'ws://192.168.18.13:8080',
    this.highAccuracyGps = true,
    this.backgroundService = true,
    this.soundAlerts = true,
    this.isDarkMode = true,
  });

  final String serverUrl;
  final bool highAccuracyGps;
  final bool backgroundService;
  final bool soundAlerts;
  final bool isDarkMode;

  AppSettings copyWith({
    String? serverUrl,
    bool? highAccuracyGps,
    bool? backgroundService,
    bool? soundAlerts,
    bool? isDarkMode,
  }) {
    return AppSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      highAccuracyGps: highAccuracyGps ?? this.highAccuracyGps,
      backgroundService: backgroundService ?? this.backgroundService,
      soundAlerts: soundAlerts ?? this.soundAlerts,
      isDarkMode: isDarkMode ?? this.isDarkMode,
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
