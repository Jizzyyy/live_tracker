import 'package:flutter/foundation.dart';

enum TrackingConnectionStatus { disconnected, reconnecting, connected }
enum TripSessionState { inactive, active, paused }

@immutable
class AppSettings {
  const AppSettings({
    this.serverUrl = 'wss://live-tracker-backend.onrender.com',
    this.userName = '',
    this.highAccuracyGps = true,
    this.backgroundService = true,
    this.isDarkMode = true,
    this.googleMapsApiKey = '',
    this.cartoApiKey = '',
    this.soundAlertsEnabled = true,
    this.hapticAlertsEnabled = true,
  });

  final String serverUrl;
  final String userName;
  final bool highAccuracyGps;
  final bool backgroundService;
  final bool isDarkMode;
  final String googleMapsApiKey;
  final String cartoApiKey;
  final bool soundAlertsEnabled;
  final bool hapticAlertsEnabled;

  AppSettings copyWith({
    String? serverUrl,
    String? userName,
    bool? highAccuracyGps,
    bool? backgroundService,
    bool? isDarkMode,
    String? googleMapsApiKey,
    String? cartoApiKey,
    bool? soundAlertsEnabled,
    bool? hapticAlertsEnabled,
  }) {
    return AppSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      userName: userName ?? this.userName,
      highAccuracyGps: highAccuracyGps ?? this.highAccuracyGps,
      backgroundService: backgroundService ?? this.backgroundService,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      googleMapsApiKey: googleMapsApiKey ?? this.googleMapsApiKey,
      cartoApiKey: cartoApiKey ?? this.cartoApiKey,
      soundAlertsEnabled: soundAlertsEnabled ?? this.soundAlertsEnabled,
      hapticAlertsEnabled: hapticAlertsEnabled ?? this.hapticAlertsEnabled,
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

  /// True if coordinate timestamp has not been updated for more than 45 seconds
  bool get isStale => DateTime.now().difference(lastUpdated).inSeconds > 45;

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

enum TacticalCueType {
  regroup,
  hazard,
  fuel,
  turnLeft,
  turnRight,
  rest,
}

extension TacticalCueTypeExt on TacticalCueType {
  String get label => switch (this) {
    TacticalCueType.regroup => 'Regroup / Kumpul',
    TacticalCueType.hazard => 'Bahaya di Depan',
    TacticalCueType.fuel => 'Isi Bensin',
    TacticalCueType.turnLeft => 'Siap Belok Kiri',
    TacticalCueType.turnRight => 'Siap Belok Kanan',
    TacticalCueType.rest => 'Istirahat / Coffee Stop',
  };

  String get shortCode => switch (this) {
    TacticalCueType.regroup => 'REGROUP',
    TacticalCueType.hazard => 'HAZARD',
    TacticalCueType.fuel => 'FUEL',
    TacticalCueType.turnLeft => 'TURN L',
    TacticalCueType.turnRight => 'TURN R',
    TacticalCueType.rest => 'REST',
  };
}

@immutable
class TacticalPing {
  final String id;
  final String userId;
  final String? senderName;
  final TacticalCueType cue;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final String? note;

  const TacticalPing({
    required this.id,
    required this.userId,
    this.senderName,
    required this.cue,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.note,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inSeconds > 8;

  String get callerDisplayName =>
      (senderName != null && senderName!.trim().isNotEmpty) ? senderName!.trim() : 'User $userId';

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    if (senderName != null) 'senderName': senderName,
    'cue': cue.name,
    if (latitude != null) 'lat': latitude,
    if (longitude != null) 'lng': longitude,
    'timestamp': timestamp.millisecondsSinceEpoch,
    if (note != null) 'note': note,
  };

  factory TacticalPing.fromJson(Map<String, dynamic> json) => TacticalPing(
    id: json['id'] as String? ?? '${DateTime.now().millisecondsSinceEpoch}',
    userId: json['userId'] as String? ?? 'unknown',
    senderName: json['senderName'] as String?,
    cue: TacticalCueType.values.firstWhere(
      (c) => c.name == json['cue'],
      orElse: () => TacticalCueType.regroup,
    ),
    latitude: (json['lat'] as num?)?.toDouble(),
    longitude: (json['lng'] as num?)?.toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    ),
    note: json['note'] as String?,
  );
}

