import 'package:flutter/foundation.dart';

enum TrackingConnectionStatus { disconnected, reconnecting, connected }

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
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      isIdle: json['isIdle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': id,
        'lat': latitude,
        'lng': longitude,
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (speedKmh != null) 'speed': speedKmh,
        if (heading != null) 'heading': heading,
        if (batteryPercent != null) 'battery': batteryPercent,
        'timestamp': lastUpdated.millisecondsSinceEpoch,
        'isIdle': isIdle,
      };

  MemberLocation copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? name,
    String? avatarUrl,
    double? speedKmh,
    double? heading,
    int? batteryPercent,
    DateTime? lastUpdated,
    bool? isIdle,
  }) {
    return MemberLocation(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      speedKmh: speedKmh ?? this.speedKmh,
      heading: heading ?? this.heading,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isIdle: isIdle ?? this.isIdle,
    );
  }
}

@immutable
class TripTelemetry {
  const TripTelemetry({
    required this.distanceMeters,
    required this.activeDurationSeconds,
    required this.currentSpeedKmh,
    required this.avgSpeedKmh,
  });

  final double distanceMeters;
  final int activeDurationSeconds;
  final double currentSpeedKmh;
  final double avgSpeedKmh;

  String get formattedDistance {
    if (distanceMeters < 1000) return '${distanceMeters.toStringAsFixed(0)} M';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} KM';
  }

  String get formattedDuration {
    final h = activeDurationSeconds ~/ 3600;
    final m = ((activeDurationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (activeDurationSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get formattedSpeed => currentSpeedKmh.toStringAsFixed(1);
}
