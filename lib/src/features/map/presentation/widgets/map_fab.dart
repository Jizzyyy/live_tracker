import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/location_provider.dart';

class MapFab extends ConsumerWidget {
  const MapFab({super.key, this.mapController});

  final MapController? mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLatLng = ref.watch(currentLatLngProvider);

    return FloatingActionButton(
      onPressed: () {
        if (currentLatLng != null && mapController != null) {
          mapController!.move(currentLatLng, 16);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menunggu sinyal GPS...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      tooltip: 'My Location',
      child: Icon(
        currentLatLng != null ? Icons.my_location : Icons.location_searching,
      ),
    );
  }
}
