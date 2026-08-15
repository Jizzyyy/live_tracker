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

class LiveTrackerScreen extends ConsumerStatefulWidget {
  const LiveTrackerScreen({super.key});

  @override
  ConsumerState<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends ConsumerState<LiveTrackerScreen> with TickerProviderStateMixin {
  final _mapController = MapController();
  bool _initialCentered = false;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
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
    final roomState = ref.watch(roomProvider);
    final posAsync = ref.watch(locationStreamProvider);
    
    // Handle Auto-centering and Position Broadcasting
    ref.listen(locationStreamProvider, (prev, next) {
      if (!next.hasValue) return;
      final pos = next.value!;
      
      ref.read(roomProvider.notifier).sendPosition(pos);

      if (!_initialCentered) {
        _animatedMapMove(LatLng(pos.latitude, pos.longitude), MapDefaults.focusedZoom);
        _initialCentered = true;
      }
    });

    // Handle Member Focus Fly-to
    ref.listen(focusedMemberProvider, (prev, next) {
      if (next != null) {
        _animatedMapMove(LatLng(next.latitude, next.longitude), 16.5);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) ref.read(focusedMemberProvider.notifier).state = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-6.2, 106.8),
              initialZoom: 13,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all), // Re-enable rotation
            ),
            children: [
              TileLayer(
                urlTemplate: mapStyle.urlTemplate,
                subdomains: mapStyle.subdomains,
                userAgentPackageName: 'com.livetracker.app',
              ),
              MarkerLayer(
                markers: roomState.members.values.map((m) {
                  return Marker(
                    point: LatLng(m.latitude, m.longitude),
                    width: 56, height: 56,
                    child: CustomUserMarker(location: m, color: _getColorForId(m.id)),
                  );
                }).toList(),
              ),
              if (posAsync.hasValue)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(posAsync.value!.latitude, posAsync.value!.longitude),
                      width: 56, height: 56,
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
          
          const Align(alignment: Alignment.topCenter, child: TopHeaderHub()),
          
          // Re-add Compass and AutoCenter widgets stacked on the right side dynamically
          Positioned(
            right: 16,
            bottom: 180, // Sit above telemetry dock cleanly
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapCompassControl(mapController: _mapController),
                const SizedBox(height: 12),
                AutoCenterButton(mapController: _mapController),
              ],
            ),
          ),
          
          const Align(alignment: Alignment.bottomCenter, child: TelemetryBottomDock()),
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
