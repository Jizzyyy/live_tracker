import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/trip_history_model.dart';
import '../utils/geo_bearing_helper.dart';

class RoutePlaybackController extends ChangeNotifier {
  final CompletedTrip trip;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0; // 1x, 2x, 5x, 10x
  int _currentIndex = 0;
  Timer? _ticker;
  double? _lastValidHeading;

  RoutePlaybackController({required this.trip});

  bool get isPlaying => _isPlaying;
  double get playbackSpeed => _playbackSpeed;
  int get currentIndex => _currentIndex;
  int get totalPoints => trip.routePoints.length;

  double get progress => totalPoints > 1 ? _currentIndex / (totalPoints - 1) : 0.0;

  RoutePoint? get currentPoint =>
      trip.routePoints.isNotEmpty && _currentIndex < trip.routePoints.length
          ? trip.routePoints[_currentIndex]
          : null;

  double? get currentHeading {
    final points = trip.routePoints;
    if (points.length < 2) return null;

    final currIdx = _currentIndex.clamp(0, points.length - 1);
    final pCurrent = points[currIdx];

    // 1. Look-ahead forward: find next distinct point (distance >= ~1.5m)
    for (int j = currIdx + 1; j < points.length; j++) {
      final pNext = points[j];
      final dLat = (pNext.latitude - pCurrent.latitude).abs();
      final dLng = (pNext.longitude - pCurrent.longitude).abs();
      // ~0.000015 deg roughly equals ~1.6m on Earth
      if (dLat > 0.000015 || dLng > 0.000015) {
        final heading = GeoBearingHelper.calculateBearingRaw(
          pCurrent.latitude,
          pCurrent.longitude,
          pNext.latitude,
          pNext.longitude,
        );
        _lastValidHeading = heading;
        return heading;
      }
    }

    // 2. Near route finish: look backward to find approach vector
    for (int j = currIdx - 1; j >= 0; j--) {
      final pPrev = points[j];
      final dLat = (pCurrent.latitude - pPrev.latitude).abs();
      final dLng = (pCurrent.longitude - pPrev.longitude).abs();
      if (dLat > 0.000015 || dLng > 0.000015) {
        final heading = GeoBearingHelper.calculateBearingRaw(
          pPrev.latitude,
          pPrev.longitude,
          pCurrent.latitude,
          pCurrent.longitude,
        );
        _lastValidHeading = heading;
        return heading;
      }
    }

    return _lastValidHeading ?? 0.0;
  }

  void play() {
    if (_isPlaying || totalPoints < 2) return;
    _isPlaying = true;
    if (_currentIndex >= totalPoints - 1) {
      _currentIndex = 0;
    }
    _startTimer();
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void setPlaybackSpeed(double speed) {
    if (_playbackSpeed == speed) return;
    _playbackSpeed = speed;
    if (_isPlaying) {
      _startTimer();
    }
    notifyListeners();
  }

  void cycleSpeed() {
    const speeds = [1.0, 2.0, 5.0, 10.0];
    final currentIdx = speeds.indexOf(_playbackSpeed);
    final nextSpeed = speeds[(currentIdx + 1) % speeds.length];
    setPlaybackSpeed(nextSpeed);
  }

  void seekToFraction(double fraction) {
    if (totalPoints < 2) return;
    final clamped = fraction.clamp(0.0, 1.0);
    _currentIndex = (clamped * (totalPoints - 1)).round();
    notifyListeners();
  }

  void seekToIndex(int index) {
    if (totalPoints < 2) return;
    _currentIndex = index.clamp(0, totalPoints - 1);
    notifyListeners();
  }

  void _startTimer() {
    _ticker?.cancel();
    // 50ms base tick interval divided by speed factor
    final ms = (80 / _playbackSpeed).round().clamp(10, 200);
    _ticker = Timer.periodic(Duration(milliseconds: ms), (t) {
      if (_currentIndex < totalPoints - 1) {
        _currentIndex++;
        notifyListeners();
      } else {
        pause();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
