import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../src/core/constants.dart';
import '../providers/tracker_providers.dart';
import '../models/tracker_models.dart';
import '../widgets/top_header_hub.dart';
import '../widgets/telemetry_dock.dart';
import '../widgets/custom_user_marker.dart';
import '../widgets/auto_center_button.dart';
import '../widgets/map_compass_control.dart';
import '../utils/ui_helpers.dart';
import '../services/background_tracking_service.dart';

class LiveTrackerScreen extends ConsumerStatefulWidget {
  const LiveTrackerScreen({super.key});

  @override
  ConsumerState<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends ConsumerState<LiveTrackerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _mapController = MapController();
  bool _initialCentered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackgroundTrackingManager.init();
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
    final posAsync = ref.watch(locationStreamProvider);
    
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: Stack(
        children: [
          // 1. High-Performance Map Viewport with Caching
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-6.2, 106.8),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
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
                userAgentPackageName: 'com.livetracker.app',
                maxZoom: 19,
                keepBuffer: 3, // Tile buffer optimization
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
                        child: CustomUserMarker(
                          location: m,
                          color: _getColorForId(m.id),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // Local User Marker Layer
              if (posAsync.hasValue)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(posAsync.value!.latitude, posAsync.value!.longitude),
                      width: 56,
                      height: 56,
                      child: CustomUserMarker(
                        isLocalUser: true,
                        location: MemberLocation(
                          id: 'YOU',
                          latitude: posAsync.value!.latitude,
                          longitude: posAsync.value!.longitude,
                          lastUpdated: posAsync.value!.timestamp,
                          heading: posAsync.value!.heading,
                          speedKmh: posAsync.value!.speed * 3.6,
                        ),
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // 2. Floating Top Header Capsule
          const Align(
            alignment: Alignment.topCenter,
            child: TopHeaderHub(),
          ),
          
          // Re-center Floating Hint Pill when user panned away
          Consumer(
            builder: (context, ref, _) {
              final isAutoFollow = ref.watch(autoFollowProvider);
              final isTracking = ref.watch(tripSessionProvider.select((s) => s.state == TripSessionState.active));
              if (isAutoFollow || !isTracking) return const SizedBox.shrink();

              return Positioned(
                top: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: PremiumGlass(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      final pos = posAsync.valueOrNull;
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
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapCompassControl(mapController: _mapController),
                const SizedBox(height: 12),
                AutoCenterButton(mapController: _mapController),
              ],
            ),
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
