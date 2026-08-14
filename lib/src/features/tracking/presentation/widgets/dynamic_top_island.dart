import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/cyber_glass.dart';
import '../../providers/tracking_providers.dart';
import '../../../../core/models/tracking_models.dart';

class DynamicTopIsland extends ConsumerWidget {
  const DynamicTopIsland({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomSessionProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: CyberGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 32.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ConnectionDot(status: roomState.status),
              const SizedBox(width: 12),
              if (roomState.roomCode != null) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: roomState.roomCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Room code copied', style: GoogleFonts.shareTechMono()),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: const Color(0xFF12151B),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Text(
                    roomState.roomCode!,
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(width: 12),
                _MemberAvatarStack(members: roomState.members.values.toList()),
              ] else ...[
                Text(
                  'DISCONNECTED',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionDot extends StatefulWidget {
  final TrackingConnectionStatus status;
  const _ConnectionDot({required this.status});

  @override
  State<_ConnectionDot> createState() => _ConnectionDotState();
}

class _ConnectionDotState extends State<_ConnectionDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.status) {
      TrackingConnectionStatus.connected => const Color(0xFF00E676),
      TrackingConnectionStatus.reconnecting => const Color(0xFFFFD600),
      TrackingConnectionStatus.disconnected => const Color(0xFFFF1744),
    };

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: widget.status == TrackingConnectionStatus.connected ? 0.2 + 0.3 * _pulseCtrl.value : 0.5),
                blurRadius: 6,
                spreadRadius: 2,
              )
            ],
          ),
        );
      },
    );
  }
}

class _MemberAvatarStack extends ConsumerWidget {
  final List<MemberLocation> members;
  const _MemberAvatarStack({required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (members.isEmpty) {
      return Text('0 USERS', style: GoogleFonts.shareTechMono(color: Colors.white.withValues(alpha: 0.5), fontSize: 12));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: members.take(4).map((m) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(selectedMemberProvider.notifier).state = m;
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF12151B),
              child: Text(
                m.id.substring(0, 1).toUpperCase(),
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
