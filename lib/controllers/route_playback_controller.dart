import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/trip_history_model.dart';

class RoutePlaybackController extends ChangeNotifier {
  final CompletedTrip trip;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0; // 1x, 2x, 5x, 10x
  int _currentIndex = 0;
  Timer? _ticker;

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
    if (trip.routePoints.length < 2) return null;
    final idx = _currentIndex.clamp(0, trip.routePoints.length - 2);
    final p1 = trip.routePoints[idx];
    final p2 = trip.routePoints[idx + 1];
    final dLat = p2.latitude - p1.latitude;
    final dLng = p2.longitude - p1.longitude;
    if (dLat == 0 && dLng == 0) return 0.0;
    if (dLng == 0) return dLat > 0 ? 0.0 : 180.0;
    final y = dLng;
    final x = dLat;
    final angle = ((90.0 - (x != 0 ? (y / x) : 0.0)) % 360.0).toDouble();
    return angle;
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
