import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/custom_snackbar.dart';

class JoinCreateRoomSheet extends ConsumerStatefulWidget {
  const JoinCreateRoomSheet({super.key});

  @override
  ConsumerState<JoinCreateRoomSheet> createState() => _JoinCreateRoomSheetState();
}

class _JoinCreateRoomSheetState extends ConsumerState<JoinCreateRoomSheet> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(roomProvider, (prev, next) {
      if (next.status == TrackingConnectionStatus.connected && next.roomCode != null && prev?.roomCode == null) {
        CustomSnackbar.show(context, message: 'Berhasil masuk ke Room \${next.roomCode}', type: SnackbarType.success);
        Navigator.pop(context);
      }
    });

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: isDark ? Colors.white30 : Colors.black26, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Group Tracking', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                
                if (roomState.status == TrackingConnectionStatus.reconnecting)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                else ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => ref.read(roomProvider.notifier).createRoom(),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text('BUAT ROOM BARU', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ATAU', style: TextStyle(color: Colors.grey))),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                  ),

                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Kode Room',
                      hintText: 'Misal: X8G9PQ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                      prefixIcon: const Icon(Icons.meeting_room_outlined),
                    ),
                    style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF)),
                  ),
                  const SizedBox(height: 16),
                  
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF00E5FF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      final code = _codeController.text.trim();
                      if (code.length >= 6) {
                        ref.read(roomProvider.notifier).joinRoom(code);
                      } else {
                        CustomSnackbar.show(context, message: 'Kode room harus 6 karakter', type: SnackbarType.error);
                      }
                    },
                    icon: const Icon(Icons.login, color: Color(0xFF00E5FF)),
                    label: Text('GABUNG ROOM', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF), letterSpacing: 1)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
