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
      color: colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.people, color: colorScheme.onPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            '${roomState.members.length} anggota',
            style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            'Kode: ${roomState.roomCode}',
            style: TextStyle(color: colorScheme.onPrimary, letterSpacing: 1.2),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: roomState.roomCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kode room disalin')),
              );
            },
            child: Icon(Icons.copy, color: colorScheme.onPrimary, size: 20),
          ),
        ],
      ),
    );
  }
}
