import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TrackingTaskHandler());
}

class TrackingTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundTask] Started at: $timestamp');
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      FlutterForegroundTask.sendDataToMain({
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
      });

      final speedKmh = (position.speed * 3.6).toStringAsFixed(1);
      FlutterForegroundTask.updateService(
        notificationTitle: 'Live Tracker Active',
        notificationText: 'Live GPS Active • $speedKmh km/h',
      );
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('[ForegroundTask] Destroyed at: $timestamp, timeout: $isTimeout');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('distance') && data.containsKey('duration')) {
        final dist = data['distance'];
        final duration = data['duration'];
        FlutterForegroundTask.updateService(
          notificationTitle: 'Live Tracker Active',
          notificationText: 'Recording Route • $dist • $duration',
        );
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_session') {
      FlutterForegroundTask.sendDataToMain({'action': 'stop_session'});
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}

class BackgroundTrackingManager {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'live_tracker_location_channel',
        channelName: 'Live Tracker Location Tracking',
        channelDescription: 'Ongoing notification keeping background tracking alive.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final reqNotification = await FlutterForegroundTask.requestNotificationPermission();
    if (reqNotification != NotificationPermission.granted) {
      debugPrint('[ForegroundTask] Notification permission denied');
    }

    final serviceResult = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Live Tracker Active',
      notificationText: 'Initializing background route recording...',
      callback: startCallback,
    );

    return serviceResult is ServiceRequestSuccess;
  }

  static Future<bool> stopService() async {
    if (!await FlutterForegroundTask.isRunningService) return true;
    final res = await FlutterForegroundTask.stopService();
    return res is ServiceRequestSuccess;
  }

  static void updateNotificationData({required String distance, required String duration}) {
    FlutterForegroundTask.sendDataToTask({
      'distance': distance,
      'duration': duration,
    });
  }
}
