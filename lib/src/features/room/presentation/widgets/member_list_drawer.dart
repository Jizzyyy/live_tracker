import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/room_provider.dart';

class MemberListDrawer extends ConsumerWidget {
  const MemberListDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Row(
              children: [
                const Icon(Icons.group, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Anggota Room',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        'Kode: ${roomState.roomCode ?? '-'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (roomState.status != RoomStatus.inRoom)
            const Expanded(
              child: Center(child: Text('Belum bergabung ke room')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: roomState.members.length,
                itemBuilder: (context, index) {
                  final memberId = roomState.members[index];
                  final isMe = memberId == roomState.userId;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        memberId.substring(0, 2).toUpperCase(),
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    title: Text(isMe ? 'Kamu ($memberId)' : 'User $memberId'),
                    subtitle: const Text('Online'),
                    trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
                  );
                },
              ),
            ),
          if (roomState.status == RoomStatus.inRoom)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(roomProvider.notifier).leaveRoom();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                label: const Text('Keluar Room', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
