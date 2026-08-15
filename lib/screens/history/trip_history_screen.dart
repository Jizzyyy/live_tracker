import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';
import 'trip_detail_screen.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Trip History', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          if (trips.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _showClearDialog(context, ref),
            ),
        ],
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No trips recorded yet', style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Start tracking to build your history.', style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Padding(
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
                              Text(trip.formattedDate, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(context, ref, trip.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatChip(icon: Icons.route, value: trip.formattedDistance, color: const Color(0xFF00E676)),
                              const SizedBox(width: 12),
                              _StatChip(icon: Icons.timer_outlined, value: trip.formattedDuration, color: const Color(0xFFFFD600)),
                              const SizedBox(width: 12),
                              _StatChip(icon: Icons.speed, value: trip.formattedAvgSpeed, color: const Color(0xFF00E5FF)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${trip.routePoints.length} GPS points recorded',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12151B),
        title: Text('Delete this trip?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () { ref.read(tripHistoryProvider.notifier).deleteTrip(id); Navigator.pop(ctx); },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12151B),
        title: Text('Clear all history?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text('All saved trips will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () { ref.read(tripHistoryProvider.notifier).clearAll(); Navigator.pop(ctx); },
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
