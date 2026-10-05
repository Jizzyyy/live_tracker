import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
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
      ref.read(telemetryExpandedProvider.notifier).state = true;
    } else {
      _expandCtrl.reverse();
      ref.read(telemetryExpandedProvider.notifier).state = false;
    }
  }

  Future<void> _handleStop(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    final saved = await ref.read(tripSessionProvider.notifier).stopSession();
    if (context.mounted) {
      CustomSnackbar.show(
        context,
        message: saved ? 'Rute tersimpan di riwayat!' : 'Rute terlalu pendek untuk disimpan (<10m).',
        type: saved ? SnackbarType.success : SnackbarType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -200) {
                _expandCtrl.forward();
                ref.read(telemetryExpandedProvider.notifier).state = true;
              } else if (details.primaryVelocity! > 200) {
                _expandCtrl.reverse();
                ref.read(telemetryExpandedProvider.notifier).state = false;
              }
            },
            child: PremiumGlass(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enableBlur: false, // Solid lightweight surface for high-frequency telemetry dock
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
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RotationTransition(
                          turns: _chevronAnimation,
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
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
                          Row(
                            children: [
                              Text(
                                'SPEED',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final isAutoPaused = ref.watch(tripSessionProvider.select((s) => s.isAutoPaused));
                                  final sessionActive = ref.watch(tripSessionProvider.select((s) => s.state == TripSessionState.active));
                                  if (!sessionActive || !isAutoPaused) return const SizedBox.shrink();

                                  return Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFFB300), width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFFB300),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AUTO PAUSED',
                                          style: GoogleFonts.shareTechMono(
                                            color: const Color(0xFFFFB300),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
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
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'km/h',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                              color: theme.colorScheme.secondary,
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
                              color: theme.colorScheme.tertiary,
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
                          Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.12), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GROUP TELEMETRY',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final count = ref.watch(roomProvider.select((r) => r.members.length));
                                  return Text(
                                    '$count Members Active',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary,
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
                                    style: GoogleFonts.inter(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                );
                              }

                              final myPos = ref.watch(locationStreamProvider).valueOrNull;
                              const distCalc = Distance();

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: members.take(4).map(
                                  (m) {
                                    final displayName = (m.name != null && m.name!.trim().isNotEmpty)
                                        ? m.name!.trim()
                                        : 'User ${m.id}';

                                    String distStr = '';
                                    if (myPos != null) {
                                      final d = distCalc.as(
                                        LengthUnit.Meter,
                                        LatLng(myPos.latitude, myPos.longitude),
                                        LatLng(m.latitude, m.longitude),
                                      );
                                      distStr = d < 1000 ? '${d.toStringAsFixed(0)} m' : '${(d / 1000).toStringAsFixed(1)} km';
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          ref.read(focusedMemberProvider.notifier).state = m;
                                          _expandCtrl.reverse();
                                          ref.read(telemetryExpandedProvider.notifier).state = false;
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 11,
                                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                                child: Text(
                                                  displayName.substring(0, 1).toUpperCase(),
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      displayName,
                                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (distStr.isNotEmpty)
                                                      Text(
                                                        distStr,
                                                        style: GoogleFonts.shareTechMono(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if (m.batteryPercent != null) ...[
                                                Icon(
                                                  m.batteryPercent! <= 20 ? Icons.battery_alert_rounded : Icons.battery_charging_full_rounded,
                                                  size: 13,
                                                  color: m.batteryPercent! <= 20 ? const Color(0xFFFF1744) : const Color(0xFF00E676),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${m.batteryPercent}%',
                                                  style: GoogleFonts.shareTechMono(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(
                                                '${(m.speedKmh ?? 0).toStringAsFixed(1)} km/h',
                                                style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.my_location_rounded,
                                                size: 14,
                                                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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

                // Trip Action Buttons with Granular 3-State Selection
                Consumer(
                  builder: (context, ref, _) {
                    final sessionState = ref.watch(tripSessionProvider.select((s) => s.state));

                    if (sessionState == TripSessionState.inactive) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref.read(tripSessionProvider.notifier).toggleSession();
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text(
                            'START TRACKING',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      );
                    }

                    if (sessionState == TripSessionState.active) {
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFFFFD600).withValues(alpha: 0.8), width: 1.5),
                                foregroundColor: const Color(0xFFFFD600),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref.read(tripSessionProvider.notifier).toggleSession();
                              },
                              icon: const Icon(Icons.pause_rounded, size: 20),
                              label: Text(
                                'JEDA',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF1744),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () => _handleStop(context, ref),
                              icon: const Icon(Icons.stop_rounded, size: 20),
                              label: Text(
                                'SELESAI',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Paused State
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              ref.read(tripSessionProvider.notifier).toggleSession();
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: Text(
                              'LANJUTKAN',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF1744), width: 1.5),
                              foregroundColor: const Color(0xFFFF1744),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: () => _handleStop(context, ref),
                            icon: const Icon(Icons.stop_rounded, size: 20),
                            label: Text(
                              'SELESAI',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
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
    final theme = Theme.of(context);
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
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
