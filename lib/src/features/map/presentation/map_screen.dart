import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../../room/presentation/room_bottom_sheet.dart';
import '../../room/presentation/widgets/connection_status_icon.dart';
import '../../room/presentation/widgets/member_list_drawer.dart';
import '../../room/presentation/widgets/room_info_bar.dart';
import '../../room/providers/room_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/location_provider.dart';
import '../providers/map_style_provider.dart';
import 'widgets/compass_button.dart';
import 'widgets/gps_signal_indicator.dart';
import 'widgets/location_info_card.dart';
import 'widgets/map_fab.dart';
import 'widgets/map_scale_bar.dart';
import 'widgets/map_style_sheet.dart';
import 'widgets/member_markers_layer.dart';
import 'widgets/member_route_layer.dart';
import 'widgets/route_polyline_layer.dart';
import 'widgets/trip_stats_card.dart';
import 'widgets/user_location_marker.dart';
import 'widgets/zoom_controls.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  bool _hasCenteredOnce = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final serverUrl = ref.read(settingsProvider);
      ref.read(roomProvider.notifier).connect(serverUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final posAsync = ref.watch(positionStreamProvider);

    final roomState = ref.watch(roomProvider);
    final mapStyle = ref.watch(mapStyleProvider);

    // Send GPS to WebSocket + auto-center on first fix (merged listener)
    ref.listen(positionStreamProvider, (prev, next) {
      if (!next.hasValue) return;
      final pos = next.value!;

      // Send to room
      ref.read(roomProvider.notifier).sendPosition(pos.latitude, pos.longitude);

      // Auto-center once
      if (!_hasCenteredOnce) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          MapDefaults.focusedZoom,
        );
        _hasCenteredOnce = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.track_changes, color: colorScheme.primary),
        title: const Text(
          'Live Tracker',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          const ConnectionStatusIcon(),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const MapStyleSheet(),
              );
            },
          ),
          const GpsSignalIndicator(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Badge(
                isLabelVisible: roomState.status == RoomStatus.inRoom,
                label: Text('${roomState.members.length}'),
                child: const Icon(Icons.group_outlined),
              ),
              onPressed: () {
                if (roomState.status == RoomStatus.inRoom) {
                  Scaffold.of(context).openEndDrawer();
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const RoomBottomSheet(),
                  );
                }
              },
            ),
          ),
        ],
      ),
      endDrawer: const MemberListDrawer(),
      body: Column(
        children: [
          const RoomInfoBar(),
          Expanded(
            child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: MapDefaults.initialCenter,
              initialZoom: MapDefaults.initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: mapStyle.urlTemplate,
                userAgentPackageName: MapDefaults.packageName,
              ),
              const MemberRouteLayer(),
              const RoutePolylineLayer(),
              const MemberMarkersLayer(),
              MarkerLayer(
                markers: [
                  ...posAsync.when(
                    data: (pos) => [
                      Marker(
                        point: LatLng(pos.latitude, pos.longitude),
                        width: 24,
                        height: 24,
                        child: const UserLocationMarker(),
                      ),
                    ],
                    loading: () => [],
                    error: (_, __) => [],
                  ),
                ],
              ),
          const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
          ),
          const LocationInfoCard(),
          const TripStatsCard(),
            Positioned(
              right: 16,
              top: 16,
              child: ZoomControls(mapController: _mapController),
            ),
            CompassButton(mapController: _mapController),
            MapScaleBar(mapController: _mapController),
          ],
        ),
        ),
      ],
      ),
      floatingActionButton: MapFab(mapController: _mapController),
    );
  }
}
