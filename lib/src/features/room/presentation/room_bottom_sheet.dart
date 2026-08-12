import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_provider.dart';

class RoomBottomSheet extends ConsumerStatefulWidget {
  const RoomBottomSheet({super.key});

  @override
  ConsumerState<RoomBottomSheet> createState() => _RoomBottomSheetState();
}

class _RoomBottomSheetState extends ConsumerState<RoomBottomSheet> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(roomProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: colorScheme.error),
        );
      }
      if (next.status == RoomStatus.inRoom && prev?.status != RoomStatus.inRoom) {
        Navigator.of(context).pop(); // Tutup bottom sheet saat berhasil masuk
      }
    });

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Group Tracking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (roomState.status == RoomStatus.connecting)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton.icon(
              onPressed: () {
                ref.read(roomProvider.notifier).createRoom();
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Room Baru'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ATAU', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Kode Room',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                final code = _codeController.text.trim();
                if (code.isNotEmpty) {
                  ref.read(roomProvider.notifier).joinRoom(code);
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Gabung Room'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
