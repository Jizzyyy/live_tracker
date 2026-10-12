import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_history_model.dart';
import '../repositories/trip_history_repository.dart';
import 'tracker_providers.dart';

// --- Trip History Provider ---
class TripHistoryNotifier extends Notifier<List<CompletedTrip>> {
  late final TripHistoryRepository _repo;

  @override
  List<CompletedTrip> build() {
    _repo = TripHistoryRepository(ref.read(sharedPrefsProvider));
    return _repo.loadAll();
  }

  Future<bool> saveTrip(CompletedTrip trip) async {
    final ok = await _repo.save(trip);
    if (ok) state = [trip, ...state];
    return ok;
  }

  Future<void> deleteTrip(String id) async {
    await _repo.delete(id);
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }
}

final tripHistoryProvider = NotifierProvider<TripHistoryNotifier, List<CompletedTrip>>(TripHistoryNotifier.new);

// --- Trip History Sorting & Memoization ---
enum TripSortOption { newest, longestDistance, longestDuration }

final tripSortOptionProvider = StateProvider<TripSortOption>((ref) => TripSortOption.newest);

final sortedTripHistoryProvider = Provider<List<CompletedTrip>>((ref) {
  final trips = ref.watch(tripHistoryProvider);
  final sortOption = ref.watch(tripSortOptionProvider);
  if (trips.isEmpty) return const [];

  final list = List<CompletedTrip>.from(trips);
  switch (sortOption) {
    case TripSortOption.newest:
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      break;
    case TripSortOption.longestDistance:
      list.sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
      break;
    case TripSortOption.longestDuration:
      list.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
      break;
  }
  return list;
});
