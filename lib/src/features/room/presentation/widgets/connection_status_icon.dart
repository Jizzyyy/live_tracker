import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/room_provider.dart';

class ConnectionStatusIcon extends ConsumerWidget {
  const ConnectionStatusIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomStatus = ref.watch(roomProvider.select((state) => state.status));

    final (Color color, String tooltip) = switch (roomStatus) {
      RoomStatus.inRoom => (Colors.green, 'Terhubung ke server'),
      RoomStatus.connecting => (Colors.orange, 'Menghubungkan...'),
      RoomStatus.disconnected => (Colors.red, 'Terputus'),
    };

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.circle, color: color, size: 10),
      ),
    );
  }
}
