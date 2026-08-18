import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/custom_snackbar.dart';
import 'trip_detail_screen.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Trip History',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF0D1117),
        ),
        actions: [
          if (trips.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: 'Clear All',
              onPressed: () => _showClearDialog(context, ref),
            ),
        ],
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route_outlined, 
                    size: 64, 
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trips recorded yet', 
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white70 : const Color(0xFF4A5568), 
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a session to build your route history.', 
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white38 : const Color(0xFF718096), 
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Dismissible(
                  key: Key(trip.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
                  ),
                  confirmDismiss: (_) async {
                    return await _confirmDelete(context, trip.id);
                  },
                  onDismissed: (_) {
                    ref.read(tripHistoryProvider.notifier).deleteTrip(trip.id);
                    CustomSnackbar.show(context, message: 'Trip deleted', type: SnackbarType.info);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PremiumGlass(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  trip.formattedDate,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16, 
                                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trip.formattedTimeRange.split(' ')[0],
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11, 
                                      color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.route, 
                                  value: trip.formattedDistance, 
                                  color: isDark ? const Color(0xFF00E676) : const Color(0xFF059669),
                                ),
                                const SizedBox(width: 12),
                                _StatChip(
                                  icon: Icons.timer_outlined, 
                                  value: trip.formattedDuration, 
                                  color: isDark ? const Color(0xFFFFD600) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 12),
                                _StatChip(
                                  icon: Icons.speed, 
                                  value: trip.formattedAvgSpeed, 
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pace: ${trip.formattedPace}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11, 
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${trip.routePoints.length} pts',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11, 
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String id) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12151B),
        title: Text('Delete this trip?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text('This action will permanently delete this route record.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12151B),
        title: Text('Clear all history?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text('All saved trips will be permanently deleted from this device.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              ref.read(tripHistoryProvider.notifier).clearAll();
              Navigator.pop(ctx);
              CustomSnackbar.show(context, message: 'All history cleared', type: SnackbarType.info);
            },
            child: const Text('DELETE ALL', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
