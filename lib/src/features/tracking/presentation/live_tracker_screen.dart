import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../providers/tracking_providers.dart';
import 'widgets/dynamic_top_island.dart';
import 'widgets/telemetry_bottom_dock.dart';
import 'widgets/custom_user_marker.dart';
import 'widgets/map_controls.dart';

class LiveTrackerScreen extends ConsumerStatefulWidget {
  const LiveTrackerScreen({super.key});

  @override
  ConsumerState<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends ConsumerState<LiveTrackerScreen> with TickerProviderStateMixin {
  final _mapController = MapController();
  bool _hasInitialCentered = false;

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket using settings or default LAN IP (handled by RoomSessionNotifier)
    Future.microtask(() => ref.read(roomSessionProvider.notifier).connect('ws://192.168.18.13:8080'));
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final posAsync = ref.watch(positionStreamProvider);
    final roomState = ref.watch(roomSessionProvider);

    // Auto-center on first GPS fix, prevent snapping if user manually panned
    ref.listen(positionStreamProvider, (prev, next) {
      if (!next.hasValue) return;
      final pos = next.value!;
      
      // Send position to server if connected
      ref.read(roomSessionProvider.notifier).sendPosition(pos);

      if (!_hasInitialCentered) {
        final currentCenter = _mapController.camera.center;
        if (currentCenter.latitude == MapDefaults.initialCenter.latitude &&
            currentCenter.longitude == MapDefaults.initialCenter.longitude) {
          _animatedMapMove(LatLng(pos.latitude, pos.longitude), MapDefaults.focusedZoom);
        }
        _hasInitialCentered = true;
      }
    });

    // Listen to selected member changes to fly camera to them
    ref.listen(selectedMemberProvider, (prev, next) {
      if (next != null) {
        _animatedMapMove(LatLng(next.latitude, next.longitude), 16.5);
        // Reset selection so it can be tapped again
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) ref.read(selectedMemberProvider.notifier).state = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: Stack(
        children: [
          // 1. Map Canvas
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: MapDefaults.initialCenter,
              initialZoom: MapDefaults.initialZoom,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Disable rotation for cleaner UI if desired, or keep it.
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: MapDefaults.packageName,
              ),
              
              // Member Markers
              MarkerLayer(
                markers: roomState.members.values.map((m) {
                  return Marker(
                    point: LatLng(m.latitude, m.longitude),
                    width: 56,
                    height: 56,
                    rotate: false, // Rotation handled internally by CustomUserMarker
                    child: CustomUserMarker(
                      location: m,
                      color: _getColorForId(m.id),
                    ),
                  );
                }).toList(),
              ),

              // Local User Marker
              if (posAsync.hasValue)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(posAsync.value!.latitude, posAsync.value!.longitude),
                      width: 56,
                      height: 56,
                      rotate: false,
                      child: CustomUserMarker(
                        location: MemberLocation(
                          id: 'YOU',
                          latitude: posAsync.value!.latitude,
                          longitude: posAsync.value!.longitude,
                          speedKmh: posAsync.value!.speed * 3.6,
                          heading: posAsync.value!.heading,
                          lastUpdated: posAsync.value!.timestamp,
                        ),
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 2. UI Overlays
          const Align(
            alignment: Alignment.topCenter,
            child: DynamicTopIsland(),
          ),

          Positioned(
            right: 16,
            bottom: 120, // Sit above telemetry dock
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapCompassControl(mapController: _mapController),
                const SizedBox(height: 12),
                AutoCenterButton(mapController: _mapController),
              ],
            ),
          ),

          const Align(
            alignment: Alignment.bottomCenter,
            child: TelemetryBottomDock(),
          ),
        ],
      ),
    );
  }

  Color _getColorForId(String id) {
    final colors = const [
      Color(0xFFFF1744), Color(0xFF00E676), Color(0xFFFFD600),
      Color(0xFFAA00FF), Color(0xFF00BCD4), Color(0xFFFF6D00),
    ];
    return colors[id.codeUnits.fold<int>(0, (p, c) => p + c) % colors.length];
  }
}
