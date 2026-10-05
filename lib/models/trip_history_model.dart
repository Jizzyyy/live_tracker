import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

@immutable
class TripSplit {
  final int kilometer;
  final int durationSeconds;
  final double avgSpeedKmh;
  final double elevationChangeMeters;

  const TripSplit({
    required this.kilometer,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    required this.elevationChangeMeters,
  });

  String get formattedPace {
    if (durationSeconds <= 0) return "--'--\"";
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    return "${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"";
  }

  String get formattedElevation {
    final prefix = elevationChangeMeters >= 0 ? '+' : '';
    return '$prefix${elevationChangeMeters.toStringAsFixed(0)} m';
  }
}

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
    this.customTitle,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.routePoints,
  });

  final String id;
  final String? customTitle;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double distanceMeters;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final List<RoutePoint> routePoints;

  /// Returns user-defined custom title if present, otherwise falls back to formatted date
  String get displayTitle => (customTitle != null && customTitle!.trim().isNotEmpty)
      ? customTitle!.trim()
      : 'Trip $formattedDate';

  // --- Strava-Grade Formatted Telemetry ---
  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${startTime.day} ${months[startTime.month - 1]} ${startTime.year}';
  }

  String get formattedTimeRange {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final diffMin = endTime.difference(startTime).inMinutes;
    return '$startStr - $endStr ($diffMin min)';
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

  /// Calculates Moving Time vs Stopped Time
  int get movingDurationSeconds {
    if (routePoints.length < 2) return durationSeconds;
    int movingSecs = 0;
    for (int i = 1; i < routePoints.length; i++) {
      final prev = routePoints[i - 1];
      final curr = routePoints[i];
      final spd = curr.speed ?? 0.0;
      if (spd > 1.5) {
        final delta = ((curr.timestamp - prev.timestamp) / 1000).round();
        if (delta > 0 && delta <= 10) {
          movingSecs += delta;
        }
      }
    }
    return movingSecs > 0 ? min(durationSeconds, movingSecs) : durationSeconds;
  }

  int get stoppedDurationSeconds => max(0, durationSeconds - movingDurationSeconds);

  String get formattedMovingDuration {
    final h = movingDurationSeconds ~/ 3600;
    final m = ((movingDurationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (movingDurationSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
  }

  String get formattedStoppedDuration {
    final h = stoppedDurationSeconds ~/ 3600;
    final m = ((stoppedDurationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (stoppedDurationSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
  }

  /// Calculates Pace in MM'SS" /km
  String get formattedPace {
    final distKm = distanceMeters / 1000;
    if (distKm <= 0.05 || durationSeconds <= 0) return "--'--\" /km";
    final totalSecondsPerKm = (durationSeconds / distKm).round();
    final paceMin = totalSecondsPerKm ~/ 60;
    final paceSec = totalSecondsPerKm % 60;
    if (paceMin > 99) return "--'--\" /km";
    return "${paceMin.toString().padLeft(2, '0')}'${paceSec.toString().padLeft(2, '0')}\" /km";
  }

  String get formattedAvgSpeed => '${avgSpeedKmh.toStringAsFixed(1)} km/h';
  String get formattedMaxSpeed => '${maxSpeedKmh.toStringAsFixed(1)} km/h';

  // --- Elevation Telemetry with Dynamic Noise Filtering ---
  double get elevationGainMeters {
    double gain = 0;
    double? lastAlt;
    for (final pt in routePoints) {
      if (pt.altitude == null) continue;
      if (lastAlt != null) {
        final diff = pt.altitude! - lastAlt;
        if (diff >= 1.5) { // 1.5m threshold to filter out GPS barometric/triangulation jitter
          gain += diff;
          lastAlt = pt.altitude;
        } else if (diff <= -1.5) {
          lastAlt = pt.altitude;
        }
      } else {
        lastAlt = pt.altitude;
      }
    }
    return gain;
  }

  double get elevationLossMeters {
    double loss = 0;
    double? lastAlt;
    for (final pt in routePoints) {
      if (pt.altitude == null) continue;
      if (lastAlt != null) {
        final diff = lastAlt - pt.altitude!;
        if (diff >= 1.5) {
          loss += diff;
          lastAlt = pt.altitude;
        } else if (diff <= -1.5) {
          lastAlt = pt.altitude;
        }
      } else {
        lastAlt = pt.altitude;
      }
    }
    return loss;
  }

  double? get minAltitude {
    final validAlts = routePoints.map((p) => p.altitude).whereType<double>().toList();
    if (validAlts.isEmpty) return null;
    return validAlts.reduce((a, b) => a < b ? a : b);
  }

  double? get maxAltitude {
    final validAlts = routePoints.map((p) => p.altitude).whereType<double>().toList();
    if (validAlts.isEmpty) return null;
    return validAlts.reduce((a, b) => a > b ? a : b);
  }

  String get formattedElevationGain {
    final gain = elevationGainMeters;
    if (gain <= 0 && minAltitude == null) return '-- m';
    return '+${gain.toStringAsFixed(0)} m';
  }

  String get formattedElevationLoss {
    final loss = elevationLossMeters;
    if (loss <= 0 && minAltitude == null) return '-- m';
    return '-${loss.toStringAsFixed(0)} m';
  }

  String get formattedMinAltitude {
    final minA = minAltitude;
    return minA != null ? '${minA.toStringAsFixed(0)} m' : '-- m';
  }

  String get formattedMaxAltitude {
    final maxA = maxAltitude;
    return maxA != null ? '${maxA.toStringAsFixed(0)} m' : '-- m';
  }

  /// Calculates maximum climb incline gradient percentage (%)
  double get maxClimbGradientPercent {
    if (routePoints.length < 2) return 0.0;
    double maxGrade = 0.0;
    double haversine(double lat1, double lon1, double lat2, double lon2) {
      const p = 0.017453292519943295;
      final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
          cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
      return 12742000 * asin(sqrt(a));
    }

    double windowDist = 0.0;
    int windowStartIndex = 0;

    for (int i = 1; i < routePoints.length; i++) {
      final p1 = routePoints[i - 1];
      final p2 = routePoints[i];
      windowDist += haversine(p1.latitude, p1.longitude, p2.latitude, p2.longitude);

      if (windowDist >= 25.0) {
        final startAlt = routePoints[windowStartIndex].altitude;
        final endAlt = p2.altitude;
        if (startAlt != null && endAlt != null) {
          final altDiff = endAlt - startAlt;
          if (altDiff > 0) {
            final grade = (altDiff / windowDist) * 100;
            if (grade > maxGrade && grade <= 45.0) {
              maxGrade = grade;
            }
          }
        }
        windowStartIndex = i;
        windowDist = 0.0;
      }
    }
    return maxGrade;
  }

  String get formattedMaxGradient {
    final grade = maxClimbGradientPercent;
    return grade > 0 ? '${grade.toStringAsFixed(1)}%' : '--%';
  }

  /// Calculates 1-kilometer splits (duration, pace, elevation change)
  List<TripSplit> get splits {
    if (routePoints.length < 2 || distanceMeters < 1000) return const [];
    final splitsList = <TripSplit>[];
    double accumulatedDist = 0.0;
    int currentKm = 1;
    int splitStartTimestamp = routePoints.first.timestamp;
    double? splitStartAlt = routePoints.first.altitude;

    double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
      const p = 0.017453292519943295; // Math.PI / 180
      final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
          cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
      return 12742000 * asin(sqrt(a)); // 2 * R * 1000 meters
    }

    for (int i = 1; i < routePoints.length; i++) {
      final prev = routePoints[i - 1];
      final curr = routePoints[i];
      final d = haversineMeters(prev.latitude, prev.longitude, curr.latitude, curr.longitude);
      accumulatedDist += d;

      if (accumulatedDist >= currentKm * 1000) {
        final splitDuration = ((curr.timestamp - splitStartTimestamp) / 1000).round();
        final eleChange = (curr.altitude != null && splitStartAlt != null)
            ? (curr.altitude! - splitStartAlt)
            : 0.0;
        final splitSpeedKmh = splitDuration > 0 ? (1.0 / (splitDuration / 3600)) : 0.0;

        splitsList.add(TripSplit(
          kilometer: currentKm,
          durationSeconds: max(1, splitDuration),
          avgSpeedKmh: splitSpeedKmh,
          elevationChangeMeters: eleChange,
        ));

        currentKm++;
        splitStartTimestamp = curr.timestamp;
        splitStartAlt = curr.altitude;
      }
    }
    return splitsList;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (customTitle != null) 'title': customTitle,
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
    customTitle: m['title'] as String?,
    startTime: DateTime.parse(m['startTime'] as String),
    endTime: DateTime.parse(m['endTime'] as String),
    durationSeconds: m['durationSeconds'] as int,
    distanceMeters: (m['distanceMeters'] as num).toDouble(),
    avgSpeedKmh: (m['avgSpeedKmh'] as num).toDouble(),
    maxSpeedKmh: (m['maxSpeedKmh'] as num).toDouble(),
    routePoints: (m['routePoints'] as List).map((p) => RoutePoint.fromMap(p as Map<String, dynamic>)).toList(),
  );

  CompletedTrip copyWith({
    String? id,
    String? Function()? customTitle,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    double? distanceMeters,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    List<RoutePoint>? routePoints,
  }) {
    return CompletedTrip(
      id: id ?? this.id,
      customTitle: customTitle != null ? customTitle() : this.customTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      routePoints: routePoints ?? this.routePoints,
    );
  }

  String toJson() => json.encode(toMap());
  factory CompletedTrip.fromJson(String source) => CompletedTrip.fromMap(json.decode(source) as Map<String, dynamic>);
}
