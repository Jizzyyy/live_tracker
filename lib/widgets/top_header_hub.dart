import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tracker_models.dart';
import '../providers/tracker_providers.dart';
import '../utils/ui_helpers.dart';
import '../screens/history/trip_history_screen.dart';
import 'modals/member_list_sheet.dart';
import 'modals/settings_sheet.dart';
import 'modals/join_create_room_sheet.dart';
import '../utils/custom_snackbar.dart';

class TopHeaderHub extends ConsumerStatefulWidget {
  const TopHeaderHub({super.key});

  @override
  ConsumerState<TopHeaderHub> createState() => _TopHeaderHubState();
}

class _TopHeaderHubState extends ConsumerState<TopHeaderHub> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: FocusScope(
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus && _isExpanded) {
                setState(() => _isExpanded = false);
              }
            },
            child: PremiumGlass(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: BorderRadius.circular(32),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _isExpanded
                      ? Row(
                          key: const ValueKey('expanded_hub'),
                          children: [
                            _PulseDot(status: roomState.status),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ActionButton(
                                    icon: Icons.map_outlined,
                                    onTap: () {
                                      setState(() => _isExpanded = false);
                                      _showMapStyleSheet(context, ref);
                                    },
                                  ),
                                  _ActionButton(
                                    icon: Icons.group_outlined,
                                    badgeCount: roomState.members.length,
                                    onTap: () {
                                      setState(() => _isExpanded = false);
                                      if (roomState.roomCode == null) {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (_) => const JoinCreateRoomSheet(),
                                        );
                                      } else {
                                        _showMemberSheet(context);
                                      }
                                    },
                                  ),
                                  _ActionButton(
                                    icon: Icons.history,
                                    onTap: () {
                                      setState(() => _isExpanded = false);
                                      _showHistorySheet(context);
                                    },
                                  ),
                                  _ActionButton(
                                    icon: Icons.settings_outlined,
                                    onTap: () {
                                      setState(() => _isExpanded = false);
                                      _showSettingsSheet(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.close_rounded,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isExpanded = false);
                              },
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('collapsed_hub'),
                          children: [
                            _PulseDot(status: roomState.status),
                            const SizedBox(width: 12),
                            Expanded(
                              child: roomState.roomCode != null
                                  ? GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Clipboard.setData(ClipboardData(text: roomState.roomCode!));
                                        CustomSnackbar.show(
                                          context,
                                          message: 'Room Code Copied!',
                                          type: SnackbarType.success,
                                        );
                                      },
                                      child: Text(
                                        roomState.roomCode!,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/app_logo.png',
                                          height: 24,
                                          width: 24,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.track_changes, size: 24, color: Color(0xFF00E5FF)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Live Tracker',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            _ActionButton(
                              icon: Icons.more_vert_rounded,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isExpanded = true);
                              },
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMapStyleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Map Style', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...availableMapStyles.map((style) {
                final isSelected = ref.watch(mapStyleProvider).id == style.id;
                return ListTile(
                  title: Text(style.name, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
                  onTap: () {
                    ref.read(mapStyleProvider.notifier).state = style;
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MemberListSheet(),
    );
  }

  void _showHistorySheet(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final TrackingConnectionStatus status;
  const _PulseDot({required this.status});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.status) {
      TrackingConnectionStatus.connected => Colors.greenAccent,
      TrackingConnectionStatus.reconnecting => Colors.amberAccent,
      TrackingConnectionStatus.disconnected => Colors.redAccent,
    };
    
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2 + 0.4 * _ctrl.value), blurRadius: 8, spreadRadius: 2)
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const _ActionButton({required this.icon, required this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
