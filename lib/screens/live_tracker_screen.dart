import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../src/core/constants.dart';
import '../providers/tracker_providers.dart';
import '../models/tracker_models.dart';
import '../widgets/top_header_hub.dart';
import '../widgets/telemetry_dock.dart';
import '../widgets/custom_user_marker.dart';
import '../widgets/auto_center_button.dart';
import '../widgets/map_compass_control.dart';
import '../utils/ui_helpers.dart';
import '../utils/sound_manager.dart';

class LiveTrackerScreen extends ConsumerStatefulWidget {
  const LiveTrackerScreen({super.key});

  @override
  ConsumerState<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends ConsumerState<LiveTrackerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _mapController = MapController();
  bool _initialCentered = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(locationStreamProvider);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_isMapReady) return; // Prevent early camera movements before binding
    
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) controller.dispose();
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final mapStyle = ref.watch(mapStyleProvider);
    
    // Auto-centering on first fix and auto-follow camera navigation
    ref.listen(locationStreamProvider, (prev, next) {
      if (!next.hasValue) return;
      final pos = next.value!;
      
      ref.read(roomProvider.notifier).sendPosition(pos);

      final isAutoFollow = ref.read(autoFollowProvider);

      if (!_initialCentered) {
        _animatedMapMove(LatLng(pos.latitude, pos.longitude), MapDefaults.focusedZoom);
        _initialCentered = true;
      } else if (isAutoFollow) {
        // Auto-follow live user movement smoothly
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom,
        );
      }
    });

    // Fly-to animation when selecting member from sheet/island
    ref.listen(focusedMemberProvider, (prev, next) {
      if (next != null) {
        _animatedMapMove(LatLng(next.latitude, next.longitude), 16.5);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) ref.read(focusedMemberProvider.notifier).state = null;
        });
      }
    });

    // Sound & Haptic Trigger on Emergency SOS
    ref.listen(roomProvider.select((r) => r.activeSos), (prev, next) {
      if (next != null && (prev == null || prev.timestamp != next.timestamp)) {
        SoundManager.playEmergencyAlarm();
        if (next.latitude != null && next.longitude != null) {
          _animatedMapMove(LatLng(next.latitude!, next.longitude!), 17.0);
        }
      }
    });

    // Sound & Haptic Trigger on Convoy Separation
    ref.listen(convoySeparationProvider.select((s) => s.isSeparated), (prev, next) {
      if (next == true && prev != true) {
        SoundManager.playWarningBeep();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: Stack(
        children: [
          // 1. High-Performance Map Viewport with Caching
          RepaintBoundary(
            child: FlutterMap(
              mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-6.2, 106.8),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
              onPositionChanged: (pos, hasGesture) {
                // If user manually drags/gestures on the map, disable auto-follow
                if (hasGesture && ref.read(autoFollowProvider)) {
                  ref.read(autoFollowProvider.notifier).state = false;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: mapStyle.urlTemplate,
                subdomains: mapStyle.subdomains,
                userAgentPackageName: 'VellumLiveTracker/1.0 (contact: kadhafiinl@github)',
                maxZoom: 19,
                keepBuffer: 1, // Tile buffer reduced from 3 to 1 to reduce RAM consumption and memory thermal pressure
              ),

              // Active Route Polyline (Throttled & Downsampled with RDP)
              Consumer(
                builder: (context, ref, _) {
                  final sessionState = ref.watch(tripSessionProvider.select((s) => s.state));
                  if (sessionState != TripSessionState.active) {
                    return const SizedBox.shrink();
                  }

                  // Watch simplified downsampled points for GPU fill-rate protection
                  final routePoints = ref.watch(
                    tripSessionProvider.notifier.select((n) => n.simplifiedRoute),
                  );

                  if (routePoints.length < 2) return const SizedBox.shrink();

                  return RepaintBoundary(
                    child: PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 4.5,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Member Markers Layer (Isolated RepaintBoundary)
              Consumer(
                builder: (context, ref, _) {
                  final members = ref.watch(roomProvider.select((r) => r.members.values.toList()));
                  return MarkerLayer(
                    markers: members.map((m) {
                      return Marker(
                        point: LatLng(m.latitude, m.longitude),
                        width: 56,
                        height: 56,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(focusedMemberProvider.notifier).state = m;
                          },
                          child: CustomUserMarker(
                            location: m,
                            color: _getColorForId(m.id),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // Local User Marker Layer (Consumer-isolated to avoid full-screen rebuilds on GPS ticks)
              Consumer(
                builder: (context, ref, _) {
                  final posAsync = ref.watch(locationStreamProvider);
                  if (!posAsync.hasValue) return const SizedBox.shrink();
                  final pos = posAsync.value!;

                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(pos.latitude, pos.longitude),
                        width: 56,
                        height: 56,
                        child: CustomUserMarker(
                          isLocalUser: true,
                          location: MemberLocation(
                            id: 'YOU',
                            latitude: pos.latitude,
                            longitude: pos.longitude,
                            lastUpdated: pos.timestamp,
                            heading: pos.heading,
                            speedKmh: pos.speed * 3.6,
                          ),
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
          
          // 2. Floating Top Header Capsule
          const Align(
            alignment: Alignment.topCenter,
            child: TopHeaderHub(),
          ),

          // 2a. Flashing Emergency SOS Alert Banner
          Consumer(
            builder: (context, ref, _) {
              final activeSos = ref.watch(roomProvider.select((r) => r.activeSos));
              if (activeSos == null) return const SizedBox.shrink();

              return Positioned(
                top: 86,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    if (activeSos.latitude != null && activeSos.longitude != null) {
                      _animatedMapMove(LatLng(activeSos.latitude!, activeSos.longitude!), 17.5);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🚨 SOS DARURAT DARI ${activeSos.userId}',
                                style: GoogleFonts.shareTechMono(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                activeSos.note,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                          onPressed: () {
                            ref.read(roomProvider.notifier).dismissSos();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 2b. Convoy Separation Watchdog Warning
          Consumer(
            builder: (context, ref, _) {
              final separation = ref.watch(convoySeparationProvider);
              final inRoom = ref.watch(roomProvider.select((r) => r.roomCode != null));
              if (!inRoom || !separation.isSeparated) return const SizedBox.shrink();

              return Positioned(
                top: 140,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fmd_bad_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Terpisah dari konvoi (~${separation.distanceMeters.toStringAsFixed(0)} m)',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Re-center Floating Hint Pill when user panned away
          Consumer(
            builder: (context, ref, _) {
              final isAutoFollow = ref.watch(autoFollowProvider);
              final isTracking = ref.watch(tripSessionProvider.select((s) => s.state == TripSessionState.active));
              if (isAutoFollow || !isTracking) return const SizedBox.shrink();

              return Positioned(
                top: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: PremiumGlass(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      final pos = ref.read(locationStreamProvider).valueOrNull;
                      if (pos != null) {
                        _animatedMapMove(LatLng(pos.latitude, pos.longitude), MapDefaults.focusedZoom);
                        ref.read(autoFollowProvider.notifier).state = true;
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed, size: 14, color: Color(0xFF00E5FF)),
                        SizedBox(width: 8),
                        Text(
                          'Ketuk untuk ikuti lokasi otomatis',
                          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // 3. Floating Micro-Controls Stack
          Consumer(
            builder: (context, ref, _) {
              final dockExpanded = ref.watch(telemetryExpandedProvider);
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: 16,
                bottom: dockExpanded ? 380 : 240,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapCompassControl(mapController: _mapController),
                    const SizedBox(height: 12),
                    AutoCenterButton(mapController: _mapController),
                  ],
                ),
              );
            },
          ),
          
          // 4. Floating Telemetry Dock
          const Align(
            alignment: Alignment.bottomCenter,
            child: TelemetryBottomDock(),
          ),
        ],
      ),
    );
  }

  Color _getColorForId(String id) {
    const colors = [
      Color(0xFFFF1744), Color(0xFF00E676), Color(0xFFFFD600),
      Color(0xFFAA00FF), Color(0xFF00BCD4), Color(0xFFFF6D00),
    ];
    return colors[id.codeUnits.fold<int>(0, (p, c) => p + c) % colors.length];
  }
}
