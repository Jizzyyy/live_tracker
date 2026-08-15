import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class MemberListSheet extends ConsumerWidget {
  const MemberListSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final members = roomState.members.values.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Group', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\${members.length} Online',
                      style: GoogleFonts.inter(color: const Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No other members in this room yet.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final m = members[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF12151B),
                          child: Text(
                            m.id.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('User \${m.id}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.speed, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('\${(m.speedKmh ?? 0).toStringAsFixed(1)} km/h', style: GoogleFonts.jetBrainsMono(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton.filledTonal(
                          icon: const Icon(Icons.my_location, size: 18),
                          onPressed: () {
                            ref.read(focusedMemberProvider.notifier).state = m;
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
                
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1744).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFFF1744),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ref.read(roomProvider.notifier).leaveRoom();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.exit_to_app),
                label: Text('LEAVE ROOM', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
