import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/room_provider.dart';

class RoomInfoBar extends ConsumerWidget {
  const RoomInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (roomState.status != RoomStatus.inRoom || roomState.roomCode == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.green.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '${roomState.members.length} anggota',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            'Kode: ${roomState.roomCode}',
            style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: roomState.roomCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kode room disalin')),
              );
            },
            child: const Icon(Icons.copy, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
