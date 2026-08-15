import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_history_model.dart';

class TripHistoryRepository {
  TripHistoryRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'completed_trips_v2';
  static const _maxTrips = 100;

  List<CompletedTrip> loadAll() {
    final raw = _prefs.getStringList(_key) ?? [];
    try {
      return raw.map((s) => CompletedTrip.fromJson(s)).toList().reversed.toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> save(CompletedTrip trip) async {
    final current = _prefs.getStringList(_key) ?? [];
    current.add(trip.toJson());
    // Trim oldest if exceeding max
    while (current.length > _maxTrips) {
      current.removeAt(0);
    }
    return _prefs.setStringList(_key, current);
  }

  Future<bool> delete(String tripId) async {
    final current = _prefs.getStringList(_key) ?? [];
    current.removeWhere((s) {
      try {
        return CompletedTrip.fromJson(s).id == tripId;
      } catch (_) {
        return false;
      }
    });
    return _prefs.setStringList(_key, current);
  }

  Future<bool> clearAll() async {
    return _prefs.remove(_key);
  }
}
