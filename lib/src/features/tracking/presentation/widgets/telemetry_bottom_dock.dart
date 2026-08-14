import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../providers/tracking_providers.dart';
import '../../../../shared/widgets/cyber_glass.dart';

class TelemetryBottomDock extends ConsumerWidget {
  const TelemetryBottomDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CyberGlassPanel(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // SPEEDOMETER
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPEED',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        telemetry.formattedSpeed,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF00E5FF),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'KM/H',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // DISTANCE & TIMER
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, size: 12, color: const Color(0xFF00E676).withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        telemetry.formattedDistance,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: const Color(0xFFFFD600).withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        telemetry.formattedDuration,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
