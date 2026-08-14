import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tracker_providers.dart';
import '../models/tracker_models.dart';
import '../utils/ui_helpers.dart';

class TelemetryBottomDock extends ConsumerWidget {
  const TelemetryBottomDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PremiumGlass(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Metrics Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Speedometer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SPEED', style: GoogleFonts.inter(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              trip.formattedSpeed,
                              style: GoogleFonts.inter(
                                fontSize: 40, 
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('km/h', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Secondary Metrics
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniMetric(icon: Icons.route_outlined, value: trip.formattedDistance),
                      const SizedBox(height: 8),
                      _MiniMetric(icon: Icons.timer_outlined, value: trip.formattedDuration),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: trip.state == TripSessionState.active ? Colors.redAccent.withValues(alpha: 0.2) : Colors.blueAccent,
                        foregroundColor: trip.state == TripSessionState.active ? Colors.redAccent : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (trip.state == TripSessionState.active) {
                          ref.read(tripSessionProvider.notifier).stopSession();
                        } else {
                          ref.read(tripSessionProvider.notifier).toggleSession();
                        }
                      },
                      child: Text(
                        trip.state == TripSessionState.active ? 'STOP SESSION' : 'START TRACKING',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                  if (trip.state == TripSessionState.active) ...[
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () => ref.read(tripSessionProvider.notifier).toggleSession(),
                      icon: const Icon(Icons.pause),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniMetric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
