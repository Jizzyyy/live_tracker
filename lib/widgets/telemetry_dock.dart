import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tracker_providers.dart';
import '../models/tracker_models.dart';
import '../utils/ui_helpers.dart';
import '../utils/custom_snackbar.dart';

class TelemetryBottomDock extends ConsumerStatefulWidget {
  const TelemetryBottomDock({super.key});

  @override
  ConsumerState<TelemetryBottomDock> createState() => _TelemetryBottomDockState();
}

class _TelemetryBottomDockState extends ConsumerState<TelemetryBottomDock> with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _chevronAnimation;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _chevronAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    if (_expandCtrl.isDismissed) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < -200) {
              _expandCtrl.forward();
            } else if (details.primaryVelocity! > 200) {
              _expandCtrl.reverse();
            }
          },
          child: PremiumGlass(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Grab Handle & Chevron indicator
                GestureDetector(
                  onTap: _toggleExpanded,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RotationTransition(
                          turns: _chevronAnimation,
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Primary Metrics Row with Granular Rebuilds via Consumer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPEED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final speedStr = ref.watch(tripSessionProvider.select((s) => s.formattedSpeed));
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    speedStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'km/h',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final dist = ref.watch(tripSessionProvider.select((s) => s.formattedDistance));
                            return _MiniMetric(
                              icon: Icons.route_outlined,
                              value: dist,
                              color: const Color(0xFF00E676),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Consumer(
                          builder: (context, ref, _) {
                            final dur = ref.watch(tripSessionProvider.select((s) => s.formattedDuration));
                            return _MiniMetric(
                              icon: Icons.timer_outlined,
                              value: dur,
                              color: const Color(0xFFFFD600),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // Smooth Physics Expandable Section
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  axis: Axis.vertical,
                  child: FadeTransition(
                    opacity: _expandAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GROUP TELEMETRY',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: Colors.white60,
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final count = ref.watch(roomProvider.select((r) => r.members.length));
                                  return Text(
                                    '$count Members Active',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF00E5FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Consumer(
                            builder: (context, ref, _) {
                              final members = ref.watch(roomProvider.select((r) => r.members.values.toList()));
                              if (members.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'No group members in room. Create or join a room to sync.',
                                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                                  ),
                                );
                              }
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: members.take(3).map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: const Color(0xFF12151B),
                                          child: Text(
                                            m.id.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(fontSize: 9, color: Color(0xFF00E5FF)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('User ${m.id}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                        const Spacer(),
                                        Text(
                                          '${(m.speedKmh ?? 0).toStringAsFixed(1)} km/h',
                                          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Trip Action Buttons with Granular State Selection
                Consumer(
                  builder: (context, ref, _) {
                    final sessionState = ref.watch(tripSessionProvider.select((s) => s.state));
                    final isActive = sessionState == TripSessionState.active;

                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : const Color(0xFF00E5FF),
                              foregroundColor: isActive
                                  ? Colors.redAccent
                                  : Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              if (isActive) {
                                final saved = await ref.read(tripSessionProvider.notifier).stopSession();
                                if (context.mounted) {
                                  CustomSnackbar.show(
                                    context,
                                    message: saved ? 'Trip saved to history!' : 'Trip too short to save.',
                                    type: saved ? SnackbarType.success : SnackbarType.warning,
                                  );
                                }
                              } else {
                                ref.read(tripSessionProvider.notifier).toggleSession();
                              }
                            },
                            child: Text(
                              isActive ? 'STOP SESSION' : 'START TRACKING',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        if (isActive) ...[
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
