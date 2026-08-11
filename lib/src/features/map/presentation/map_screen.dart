import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../providers/location_provider.dart';
import 'widgets/gps_signal_indicator.dart';
import 'widgets/location_info_card.dart';
import 'widgets/map_fab.dart';
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final posAsync = ref.watch(positionStreamProvider);

    // Auto-center on first GPS fix
    ref.listen(positionStreamProvider, (prev, next) {
      if (!_hasCenteredOnce && next.hasValue) {
        final pos = next.value!;
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
          const GpsSignalIndicator(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: MapDefaults.initialCenter,
              initialZoom: MapDefaults.initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: MapDefaults.tileUrl,
                userAgentPackageName: MapDefaults.packageName,
              ),
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
          Positioned(
            right: 16,
            top: 16,
            child: ZoomControls(mapController: _mapController),
          ),
        ],
      ),
      floatingActionButton: MapFab(mapController: _mapController),
    );
  }
}
