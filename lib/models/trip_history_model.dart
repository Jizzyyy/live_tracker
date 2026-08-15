import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class RoutePoint {
  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.altitude,
  });

  final double latitude;
  final double longitude;
  final int timestamp;
  final double? speed;
  final double? altitude;

  Map<String, dynamic> toMap() => {
    'lat': latitude,
    'lng': longitude,
    'ts': timestamp,
    if (speed != null) 'spd': speed,
    if (altitude != null) 'alt': altitude,
  };

  factory RoutePoint.fromMap(Map<String, dynamic> m) => RoutePoint(
    latitude: (m['lat'] as num).toDouble(),
    longitude: (m['lng'] as num).toDouble(),
    timestamp: m['ts'] as int,
    speed: (m['spd'] as num?)?.toDouble(),
    altitude: (m['alt'] as num?)?.toDouble(),
  );
}

@immutable
class CompletedTrip {
  const CompletedTrip({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.routePoints,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double distanceMeters;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final List<RoutePoint> routePoints;

  // --- Formatted Getters ---
  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${startTime.day} ${months[startTime.month - 1]} ${startTime.year}, '
           '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distanceMeters < 1000) return '${distanceMeters.toStringAsFixed(0)} m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = ((durationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
  }

  String get formattedAvgSpeed => '${avgSpeedKmh.toStringAsFixed(1)} km/h';
  String get formattedMaxSpeed => '${maxSpeedKmh.toStringAsFixed(1)} km/h';

  // --- Serialization ---
  Map<String, dynamic> toMap() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationSeconds': durationSeconds,
    'distanceMeters': distanceMeters,
    'avgSpeedKmh': avgSpeedKmh,
    'maxSpeedKmh': maxSpeedKmh,
    'routePoints': routePoints.map((p) => p.toMap()).toList(),
  };

  factory CompletedTrip.fromMap(Map<String, dynamic> m) => CompletedTrip(
    id: m['id'] as String,
    startTime: DateTime.parse(m['startTime'] as String),
    endTime: DateTime.parse(m['endTime'] as String),
    durationSeconds: m['durationSeconds'] as int,
    distanceMeters: (m['distanceMeters'] as num).toDouble(),
    avgSpeedKmh: (m['avgSpeedKmh'] as num).toDouble(),
    maxSpeedKmh: (m['maxSpeedKmh'] as num).toDouble(),
    routePoints: (m['routePoints'] as List).map((p) => RoutePoint.fromMap(p as Map<String, dynamic>)).toList(),
  );

  String toJson() => json.encode(toMap());
  factory CompletedTrip.fromJson(String source) => CompletedTrip.fromMap(json.decode(source) as Map<String, dynamic>);
}
