import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class TripHistorySheet extends ConsumerWidget {
  const TripHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(tripHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white30 : Colors.black26, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trip History', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (history.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showClearDialog(context, ref),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No trips recorded yet.', style: GoogleFonts.inter(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Start tracking to see your history.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final trip = history[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trip.formattedDate, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(trip.formattedDistance, style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E676), fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Text(trip.formattedDuration, style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFFD600))),
                                      const SizedBox(width: 12),
                                      Text('\${trip.avgSpeedKmh.toStringAsFixed(1)} km/h avg', style: GoogleFonts.jetBrainsMono(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12151B),
        title: Text('Clear History?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete all your saved trips from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              ref.read(tripHistoryProvider.notifier).clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('DELETE ALL', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
